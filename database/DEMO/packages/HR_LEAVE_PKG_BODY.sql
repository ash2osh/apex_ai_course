
  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "DEMO"."HR_LEAVE_PKG" AS

    FUNCTION calculate_days(
        p_start_date IN DATE,
        p_end_date   IN DATE
    ) RETURN NUMBER IS
        l_days  NUMBER := 0;
        l_curr  DATE;
        l_day_n NUMBER;
    BEGIN
        IF p_start_date IS NULL OR p_end_date IS NULL THEN
            RETURN 0;
        END IF;

        IF TRUNC(p_end_date) < TRUNC(p_start_date) THEN
            RAISE_APPLICATION_ERROR(-20010, 'End date cannot be prior to start date');
        END IF;

        l_curr := TRUNC(p_start_date);
        WHILE l_curr <= TRUNC(p_end_date) LOOP
            -- 1 = Sunday, 7 = Saturday in standard Oracle format
            l_day_n := TO_NUMBER(TO_CHAR(l_curr, 'D'));
            IF l_day_n NOT IN (1, 7) THEN
                l_days := l_days + 1;
            END IF;
            l_curr := l_curr + 1;
        END LOOP;

        RETURN l_days;
    END calculate_days;

    FUNCTION get_available_days(
        p_user_id       IN NUMBER,
        p_leave_type_id IN NUMBER,
        p_year          IN NUMBER DEFAULT EXTRACT(YEAR FROM SYSDATE)
    ) RETURN NUMBER IS
        l_available NUMBER;
    BEGIN
        SELECT (entitlement_days + adjustment_days - used_days - pending_days)
          INTO l_available
          FROM hr_leave_balances
         WHERE user_id = p_user_id
           AND leave_type_id = p_leave_type_id
           AND balance_year = p_year;

        RETURN NVL(l_available, 0);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN 0;
    END get_available_days;

    FUNCTION get_available_days(
        p_username        IN VARCHAR2,
        p_leave_type_code IN VARCHAR2,
        p_year            IN NUMBER DEFAULT EXTRACT(YEAR FROM SYSDATE)
    ) RETURN NUMBER IS
        l_user_id       NUMBER;
        l_leave_type_id NUMBER;
    BEGIN
        l_user_id := hr_user_pkg.get_user_id(p_username);
        IF l_user_id IS NULL THEN
            RETURN 0;
        END IF;

        SELECT leave_type_id
          INTO l_leave_type_id
          FROM hr_leave_types
         WHERE UPPER(leave_type_code) = UPPER(TRIM(p_leave_type_code));

        RETURN get_available_days(l_user_id, l_leave_type_id, p_year);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN 0;
    END get_available_days;

    FUNCTION validate_overlap(
        p_user_id            IN NUMBER,
        p_start_date         IN DATE,
        p_end_date           IN DATE,
        p_exclude_request_id IN NUMBER DEFAULT NULL
    ) RETURN BOOLEAN IS
        l_count PLS_INTEGER;
    BEGIN
        SELECT COUNT(*)
          INTO l_count
          FROM hr_leave_requests
         WHERE user_id = p_user_id
           AND status NOT IN ('REJECTED', 'CANCELLED')
           AND (p_exclude_request_id IS NULL OR request_id != p_exclude_request_id)
           AND TRUNC(start_date) <= TRUNC(p_end_date)
           AND TRUNC(end_date)   >= TRUNC(p_start_date);

        RETURN (l_count > 0);
    END validate_overlap;

    PROCEDURE record_event(
        p_request_id     IN NUMBER,
        p_event_type     IN VARCHAR2,
        p_from_status    IN VARCHAR2,
        p_to_status      IN VARCHAR2,
        p_actor_username IN VARCHAR2,
        p_comments       IN VARCHAR2 DEFAULT NULL
    ) IS
    BEGIN
        INSERT INTO hr_leave_request_events (
            request_id,
            event_type,
            from_status,
            to_status,
            actor_username,
            comments,
            event_timestamp
        ) VALUES (
            p_request_id,
            p_event_type,
            p_from_status,
            p_to_status,
            NVL(p_actor_username, hr_user_pkg.current_username),
            p_comments,
            SYSTIMESTAMP
        );
    END record_event;

    PROCEDURE create_request(
        p_username        IN VARCHAR2,
        p_leave_type_code IN VARCHAR2,
        p_start_date      IN DATE,
        p_end_date        IN DATE,
        p_reason          IN VARCHAR2 DEFAULT NULL,
        p_request_id      OUT NUMBER
    ) IS
        l_user_id        NUMBER;
        l_leave_type_id  NUMBER;
        l_requires_bal   VARCHAR2(1);
        l_type_active    VARCHAR2(1);
        l_requested_days NUMBER;
        l_year           NUMBER;
        l_balance_id     NUMBER;
        l_entitlement    NUMBER;
        l_adjustment     NUMBER;
        l_used           NUMBER;
        l_pending        NUMBER;
        l_available      NUMBER;
    BEGIN
        -- 1. Resolve User
        l_user_id := hr_user_pkg.get_user_id(p_username);
        IF l_user_id IS NULL THEN
            RAISE_APPLICATION_ERROR(-20011, 'Invalid or unknown user: ' || p_username);
        END IF;

        IF NOT hr_user_pkg.is_active_user(l_user_id) THEN
            RAISE_APPLICATION_ERROR(-20012, 'Employee account is inactive');
        END IF;

        -- 2. Resolve Leave Type
        BEGIN
            SELECT leave_type_id, requires_balance_yn, active_yn
              INTO l_leave_type_id, l_requires_bal, l_type_active
              FROM hr_leave_types
             WHERE UPPER(leave_type_code) = UPPER(TRIM(p_leave_type_code));
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20013, 'Invalid leave type: ' || p_leave_type_code);
        END;

        IF l_type_active != 'Y' THEN
            RAISE_APPLICATION_ERROR(-20014, 'Selected leave type is inactive');
        END IF;

        -- 3. Validate Dates & Compute Days
        IF p_start_date IS NULL OR p_end_date IS NULL THEN
            RAISE_APPLICATION_ERROR(-20015, 'Start date and end date are required');
        END IF;

        l_requested_days := calculate_days(p_start_date, p_end_date);
        IF l_requested_days <= 0 THEN
            RAISE_APPLICATION_ERROR(-20016, 'Requested duration must be at least 1 working day');
        END IF;

        -- 4. Check Overlap
        IF validate_overlap(l_user_id, p_start_date, p_end_date) THEN
            RAISE_APPLICATION_ERROR(-20017, 'Leave request overlaps with an existing active request');
        END IF;

        l_year := EXTRACT(YEAR FROM p_start_date);

        -- 5. Atomic Balance Reservation with Row-Level Lock
        IF l_requires_bal = 'Y' THEN
            BEGIN
                SELECT balance_id, entitlement_days, adjustment_days, used_days, pending_days
                  INTO l_balance_id, l_entitlement, l_adjustment, l_used, l_pending
                  FROM hr_leave_balances
                 WHERE user_id = l_user_id
                   AND leave_type_id = l_leave_type_id
                   AND balance_year = l_year
                   FOR UPDATE;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    RAISE_APPLICATION_ERROR(-20018, 'No leave balance allocated for year ' || l_year);
            END;

            l_available := l_entitlement + l_adjustment - l_used - l_pending;
            IF l_available < l_requested_days THEN
                RAISE_APPLICATION_ERROR(-20019,
                    'Insufficient leave balance. Available: ' || l_available ||
                    ' day(s), Requested: ' || l_requested_days || ' day(s)');
            END IF;

            -- Reserve pending days atomically
            UPDATE hr_leave_balances
               SET pending_days = pending_days + l_requested_days
             WHERE balance_id = l_balance_id;
        END IF;

        -- 6. Insert Request
        INSERT INTO hr_leave_requests (
            user_id,
            leave_type_id,
            start_date,
            end_date,
            requested_days,
            reason,
            status
        ) VALUES (
            l_user_id,
            l_leave_type_id,
            TRUNC(p_start_date),
            TRUNC(p_end_date),
            l_requested_days,
            p_reason,
            'PENDING_MANAGER_APPROVAL'
        ) RETURNING request_id INTO p_request_id;

        -- 7. Record Lifecycle Event
        record_event(
            p_request_id     => p_request_id,
            p_event_type     => 'SUBMITTED',
            p_from_status    => 'DRAFT',
            p_to_status      => 'PENDING_MANAGER_APPROVAL',
            p_actor_username => UPPER(p_username),
            p_comments       => p_reason
        );

    END create_request;

    PROCEDURE approve_request(
        p_request_id     IN NUMBER,
        p_actor_username IN VARCHAR2,
        p_comments       IN VARCHAR2 DEFAULT NULL
    ) IS
        l_user_id        NUMBER;
        l_leave_type_id  NUMBER;
        l_start_date     DATE;
        l_requested_days NUMBER;
        l_status         VARCHAR2(30);
        l_requires_bal   VARCHAR2(1);
        l_year           NUMBER;
    BEGIN
        -- 1. Lock and validate request
        SELECT r.user_id, r.leave_type_id, r.start_date, r.requested_days, r.status,
               t.requires_balance_yn
          INTO l_user_id, l_leave_type_id, l_start_date, l_requested_days, l_status,
               l_requires_bal
          FROM hr_leave_requests r
          JOIN hr_leave_types t ON t.leave_type_id = r.leave_type_id
         WHERE r.request_id = p_request_id
           FOR UPDATE OF r.status;

        IF l_status NOT IN ('SUBMITTED', 'PENDING', 'PENDING_MANAGER_APPROVAL', 'PENDING_HR_APPROVAL') THEN
            RAISE_APPLICATION_ERROR(-20020, 'Request is not in an approvable state: ' || l_status);
        END IF;

        -- 2. Authorization check
        IF NOT hr_auth_pkg.can_approve_request(p_actor_username, p_request_id) THEN
            RAISE_APPLICATION_ERROR(-20021, 'Actor is not authorized to approve this leave request');
        END IF;

        -- 3. Atomic Balance Transition: PENDING -> USED
        IF l_requires_bal = 'Y' THEN
            l_year := EXTRACT(YEAR FROM l_start_date);
            UPDATE hr_leave_balances
               SET pending_days = GREATEST(0, pending_days - l_requested_days),
                   used_days    = used_days + l_requested_days
             WHERE user_id = l_user_id
               AND leave_type_id = l_leave_type_id
               AND balance_year = l_year;
        END IF;

        -- 4. Update Request Status
        UPDATE hr_leave_requests
           SET status = 'APPROVED'
         WHERE request_id = p_request_id;

        -- 5. Record Event
        record_event(
            p_request_id     => p_request_id,
            p_event_type     => 'APPROVED',
            p_from_status    => l_status,
            p_to_status      => 'APPROVED',
            p_actor_username => p_actor_username,
            p_comments       => p_comments
        );

    END approve_request;

    PROCEDURE reject_request(
        p_request_id     IN NUMBER,
        p_actor_username IN VARCHAR2,
        p_comments       IN VARCHAR2 DEFAULT NULL
    ) IS
        l_user_id        NUMBER;
        l_leave_type_id  NUMBER;
        l_start_date     DATE;
        l_requested_days NUMBER;
        l_status         VARCHAR2(30);
        l_requires_bal   VARCHAR2(1);
        l_year           NUMBER;
    BEGIN
        -- 1. Lock and validate request
        SELECT r.user_id, r.leave_type_id, r.start_date, r.requested_days, r.status,
               t.requires_balance_yn
          INTO l_user_id, l_leave_type_id, l_start_date, l_requested_days, l_status,
               l_requires_bal
          FROM hr_leave_requests r
          JOIN hr_leave_types t ON t.leave_type_id = r.leave_type_id
         WHERE r.request_id = p_request_id
           FOR UPDATE OF r.status;

        IF l_status NOT IN ('SUBMITTED', 'PENDING', 'PENDING_MANAGER_APPROVAL', 'PENDING_HR_APPROVAL') THEN
            RAISE_APPLICATION_ERROR(-20022, 'Request is not in a rejectable state: ' || l_status);
        END IF;

        -- 2. Authorization check
        IF NOT hr_auth_pkg.can_approve_request(p_actor_username, p_request_id) THEN
            RAISE_APPLICATION_ERROR(-20023, 'Actor is not authorized to reject this leave request');
        END IF;

        -- 3. Release reserved pending days
        IF l_requires_bal = 'Y' THEN
            l_year := EXTRACT(YEAR FROM l_start_date);
            UPDATE hr_leave_balances
               SET pending_days = GREATEST(0, pending_days - l_requested_days)
             WHERE user_id = l_user_id
               AND leave_type_id = l_leave_type_id
               AND balance_year = l_year;
        END IF;

        -- 4. Update Request Status
        UPDATE hr_leave_requests
           SET status = 'REJECTED'
         WHERE request_id = p_request_id;

        -- 5. Record Event
        record_event(
            p_request_id     => p_request_id,
            p_event_type     => 'REJECTED',
            p_from_status    => l_status,
            p_to_status      => 'REJECTED',
            p_actor_username => p_actor_username,
            p_comments       => p_comments
        );

    END reject_request;

    PROCEDURE cancel_request(
        p_request_id     IN NUMBER,
        p_actor_username IN VARCHAR2,
        p_reason         IN VARCHAR2 DEFAULT NULL
    ) IS
        l_user_id        NUMBER;
        l_leave_type_id  NUMBER;
        l_start_date     DATE;
        l_requested_days NUMBER;
        l_status         VARCHAR2(30);
        l_requires_bal   VARCHAR2(1);
        l_year           NUMBER;
    BEGIN
        -- 1. Lock and validate request
        SELECT r.user_id, r.leave_type_id, r.start_date, r.requested_days, r.status,
               t.requires_balance_yn
          INTO l_user_id, l_leave_type_id, l_start_date, l_requested_days, l_status,
               l_requires_bal
          FROM hr_leave_requests r
          JOIN hr_leave_types t ON t.leave_type_id = r.leave_type_id
         WHERE r.request_id = p_request_id
           FOR UPDATE OF r.status;

        -- 2. Authorization check
        IF NOT hr_auth_pkg.can_cancel_request(p_actor_username, p_request_id) THEN
            RAISE_APPLICATION_ERROR(-20024, 'Request cannot be cancelled or actor is not authorized');
        END IF;

        -- 3. Release reserved pending days
        IF l_requires_bal = 'Y' THEN
            l_year := EXTRACT(YEAR FROM l_start_date);
            UPDATE hr_leave_balances
               SET pending_days = GREATEST(0, pending_days - l_requested_days)
             WHERE user_id = l_user_id
               AND leave_type_id = l_leave_type_id
               AND balance_year = l_year;
        END IF;

        -- 4. Update Request Status
        UPDATE hr_leave_requests
           SET status = 'CANCELLED'
         WHERE request_id = p_request_id;

        -- 5. Record Event
        record_event(
            p_request_id     => p_request_id,
            p_event_type     => 'CANCELLED',
            p_from_status    => l_status,
            p_to_status      => 'CANCELLED',
            p_actor_username => p_actor_username,
            p_comments       => p_reason
        );

    END cancel_request;

    PROCEDURE adjust_balance(
        p_user_id          IN NUMBER,
        p_leave_type_code  IN VARCHAR2,
        p_year             IN NUMBER,
        p_adjustment_delta IN NUMBER,
        p_actor_username   IN VARCHAR2,
        p_reason           IN VARCHAR2
    ) IS
        l_leave_type_id NUMBER;
        l_balance_id    NUMBER;
    BEGIN
        -- 1. Authorization check
        hr_auth_pkg.assert_admin(p_actor_username);

        IF p_reason IS NULL OR TRIM(p_reason) IS NULL THEN
            RAISE_APPLICATION_ERROR(-20025, 'Audit reason is mandatory for balance adjustment');
        END IF;

        SELECT leave_type_id
          INTO l_leave_type_id
          FROM hr_leave_types
         WHERE UPPER(leave_type_code) = UPPER(TRIM(p_leave_type_code));

        BEGIN
            SELECT balance_id
              INTO l_balance_id
              FROM hr_leave_balances
             WHERE user_id = p_user_id
               AND leave_type_id = l_leave_type_id
               AND balance_year = p_year
               FOR UPDATE;

            UPDATE hr_leave_balances
               SET adjustment_days = adjustment_days + p_adjustment_delta
             WHERE balance_id = l_balance_id;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                INSERT INTO hr_leave_balances (
                    user_id,
                    leave_type_id,
                    balance_year,
                    entitlement_days,
                    used_days,
                    pending_days,
                    adjustment_days
                ) VALUES (
                    p_user_id,
                    l_leave_type_id,
                    p_year,
                    0,
                    0,
                    0,
                    p_adjustment_delta
                );
        END;

    END adjust_balance;

END hr_leave_pkg;
/
