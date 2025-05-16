-- 1) Первый запрос.
--
-- Получить распределения заказов по дням недели и времени с шагом в 3 часа. 
-- Статистика рассчитывается только по тем дням, в которых был хотя бы один заказ. 
--
-- Результат представить в виде 56 строк:
-- День недели; период времени (например, 09:00 – 12:00). 
--
-- Все следующие параметры рассчитываются для данного дня недели и периода времени: 
-- общее число заказов за все время работы таксопарка; общая сумма заказов; 
-- среднее число заказов в день в этот период времени; является ли этот промежуток 
-- времени самым нагруженным в данный день недели (да/нет); является ли этот промежуток 
-- времени самым нагруженным  в неделе (да/нет).

WITH all_combinations AS ( -- Генерация всех возможных комбинаций дня и периода времени
  SELECT 
    day_num,
    time_period
  FROM 
    (VALUES (0), (1), (2), (3), (4), (5), (6)) AS days(day_num), -- тут создается декартово произведение таблиц, потому что они объявлены через запятую
    (VALUES 
      ('00:00 – 03:00'),
      ('03:00 – 06:00'),
      ('06:00 – 09:00'),
      ('09:00 – 12:00'),
      ('12:00 – 15:00'),
      ('15:00 – 18:00'),
      ('18:00 – 21:00'),
      ('21:00 – 00:00')
    ) AS intervals(time_period)
),

order_stats AS ( -- анализируем данные о заказах
  SELECT 
    EXTRACT(DOW FROM start_date) AS day_of_week, -- выделяем день недели (0-вскр, 6-сб)
    CASE -- выделяем временной промежуток
      WHEN EXTRACT(HOUR FROM start_date) BETWEEN 0 AND 2 THEN '00:00 – 03:00'
      WHEN EXTRACT(HOUR FROM start_date) BETWEEN 3 AND 5 THEN '03:00 – 06:00'
      WHEN EXTRACT(HOUR FROM start_date) BETWEEN 6 AND 8 THEN '06:00 – 09:00'
      WHEN EXTRACT(HOUR FROM start_date) BETWEEN 9 AND 11 THEN '09:00 – 12:00'
      WHEN EXTRACT(HOUR FROM start_date) BETWEEN 12 AND 14 THEN '12:00 – 15:00'
      WHEN EXTRACT(HOUR FROM start_date) BETWEEN 15 AND 17 THEN '15:00 – 18:00'
      WHEN EXTRACT(HOUR FROM start_date) BETWEEN 18 AND 20 THEN '18:00 – 21:00'
      WHEN EXTRACT(HOUR FROM start_date) BETWEEN 21 AND 23 THEN '21:00 – 00:00'
    END AS time_period,
    COUNT(*) AS total_orders, -- считаем суммарное количество заказов для каждого промежутка времени
    COALESCE(SUM(ip.payment_sum), 0) AS total_amount, -- суммируем платежи,  COALESCE заменяет NULL на 0
    COUNT(DISTINCT DATE(start_date)) AS days_with_orders -- считаем количество уникальных дней с этим промежутком времени. Это нужно для расчета среднего числа заказов в условный понедельник с 6 до 9 утра и т.д.
  FROM taxi_order t
  LEFT JOIN input_payment ip ON t.input_payment_id = ip.input_payment_id -- потому что заказы без оплаты тоже должны быть учтены
  GROUP BY day_of_week, time_period
),

daily_max AS ( -- для каждого дня получаем максимальное количество заказов
  SELECT 
    day_of_week,
    MAX(total_orders) AS max_orders_per_day
  FROM order_stats
  GROUP BY day_of_week
),

weekly_max AS ( -- получаем максимальное количество заказов вообще
  SELECT 
    MAX(total_orders) AS max_orders_week
  FROM order_stats
)

SELECT -- основной запрос
  CASE -- определяем день недели из таблицы all_combinations
    WHEN ac.day_num = 0 THEN 'Sunday'
    WHEN ac.day_num = 1 THEN 'Monday'
    WHEN ac.day_num = 2 THEN 'Tuesday'
    WHEN ac.day_num = 3 THEN 'Wednesday'
    WHEN ac.day_num = 4 THEN 'Thursday'
    WHEN ac.day_num = 5 THEN 'Friday'
    WHEN ac.day_num = 6 THEN 'Saturday'
  END AS day_of_week,
  ac.time_period, -- временной период из таблицы all_combinations
  COALESCE(os.total_orders, 0) AS total_orders, -- подставляем либо количество всех заказов, либо 0
  COALESCE(ROUND(os.total_amount::numeric, 2), 0) AS total_amount, -- либо сумма по этому промежутку, либо 0
  CASE -- среднее число заказов в день в этом промежутке времени, days_with_orders это число уникальных дней с заказами в этом временном промежутке. А total_orders это суммарное число заказов в этот день в этом промежутке времени.
    WHEN COALESCE(os.days_with_orders, 0) = 0 THEN 0
    ELSE ROUND(COALESCE(os.total_orders, 0)::numeric / os.days_with_orders, 2)
  END AS avg_orders_per_day,
  CASE -- самый нагруженный промежуток в этот день
    WHEN os.total_orders IS NULL THEN 'no'
    WHEN os.total_orders = dm.max_orders_per_day THEN 'yes' 
    ELSE 'no' 
  END AS is_busiest_in_day,
  CASE -- самый нагруженный промежуток в неделе
    WHEN os.total_orders IS NULL THEN 'no'
    WHEN os.total_orders = wm.max_orders_week THEN 'yes' 
    ELSE 'no' 
  END AS is_busiest_in_week
FROM all_combinations ac
LEFT JOIN order_stats os ON ac.day_num = os.day_of_week AND ac.time_period = os.time_period -- соеденяем все с  помощью LEFT JOIN чтобы вывести 56 все строк
LEFT JOIN daily_max dm ON ac.day_num = dm.day_of_week
CROSS JOIN weekly_max wm -- присоеденяем максимум к каждой строке тк weekly_max имеет только одну строку
ORDER BY ac.day_num, ac.time_period;











-- 2) Второй запрос.
--
-- Получить отчет по работе водителей на автомобилях (отчет по договорам), представить в следующем виде:
-- Имя водителя; название автомобиля; номер договора; дата начала договора; дата окончания договора; 
-- актуален ли договор (да/нет); число выполненных заказов по договору; число отказов по договору; 
-- сумма заказов по договору; сумма платежей водителю.

WITH driver_contracts AS ( -- статистика по контрактам
  SELECT 
    c.contract_id,
    c.start_date,
    c.end_date,
    c.taxi_user_id AS driver_id,
    c.car_registration_id,
    c.taxi_pool_id,
    CONCAT(u.first_name, ' ', u.last_name) AS driver_name, -- соеденяем фамилию и имя водителя
    car.car_brand_name,
    CASE -- определяем действующий ли договор
      WHEN CURRENT_TIMESTAMP BETWEEN c.start_date AND c.end_date THEN 'yes'
      ELSE 'no'
    END AS is_active
  FROM contract c
  JOIN taxi_user u ON c.taxi_user_id = u.taxi_user_id -- присоеденяем всех водителей
  JOIN car ON c.car_registration_id = car.car_registration_id -- присоеденяем все машины
),

completed_orders AS ( -- статистика по выполненным заказам 
  SELECT 
    c.contract_id,
    COUNT(DISTINCT o.taxi_order_id) AS completed_orders_count, -- количество уникальных выполненных заказов для водителя (сумма группе)
    SUM(tt.trip_tariff * EXTRACT(EPOCH FROM (o.end_date - o.start_date))/60) AS total_orders_sum -- сколько водитель принес суммарно денег. EPOCH для получения количества секунд в интервале. 
  FROM driver_contracts c
  JOIN taxi_order o ON o.driver_id = c.driver_id
  JOIN trip_type tt ON o.trip_type_id = tt.trip_type_id
  WHERE o.taxi_order_status_id IN (SELECT taxi_order_status_id FROM taxi_order_status WHERE status_name = 'ride_completed')
    AND o.start_date BETWEEN c.start_date AND c.end_date -- выбираем только для этого договора именно
  GROUP BY c.contract_id
),

driver_rejections AS ( -- статистика по отказам
  SELECT 
    c.contract_id,
    COUNT(DISTINCT r.driver_rejection_id) AS rejections_count -- считаем количество уникальных отказов
  FROM driver_contracts c
  JOIN driver_rejection r ON r.driver_id = c.driver_id
  JOIN taxi_order o ON r.taxi_order_id = o.taxi_order_id
  WHERE o.start_date BETWEEN c.start_date AND c.end_date -- только для этого договора
  GROUP BY c.contract_id
),

driver_payments AS ( -- статистика по выплатам водителям по контрактам
  SELECT 
    c.contract_id,
    SUM(p.payment_sum) AS total_payments
  FROM driver_contracts c
  JOIN output_payment p ON p.driver_id = c.driver_id
  WHERE p.date BETWEEN c.start_date AND c.end_date
  GROUP BY c.contract_id
)

SELECT -- основной запрос
  dc.driver_name AS "Driver name",
  dc.car_brand_name AS "Car name",
  dc.contract_id AS "Contract number",
  TO_CHAR(dc.start_date, 'DD.MM.YYYY') AS "Start date of the agreement", -- делаем красиво дату
  TO_CHAR(dc.end_date, 'DD.MM.YYYY') AS "End date of the agreement", -- делаем красиво дату
  dc.is_active AS "Is the agreement relevant",
  COALESCE(co.completed_orders_count, 0) AS "Number of completed orders",
  COALESCE(dr.rejections_count, 0) AS "Bounce rate",
  ROUND(COALESCE(co.total_orders_sum, 0)::numeric, 2) AS "The amount of orders under the agreement",
  ROUND(COALESCE(dp.total_payments, 0)::numeric, 2) AS "The amount of payments to the driver"
FROM driver_contracts dc
LEFT JOIN completed_orders co ON dc.contract_id = co.contract_id
LEFT JOIN driver_rejections dr ON dc.contract_id = dr.contract_id
LEFT JOIN driver_payments dp ON dc.contract_id = dp.contract_id
ORDER BY dc.driver_name, dc.start_date DESC \gx


-- 3) Третий запрос.
--
-- Получить отчет по клиентам таксопарка в виде:
-- Имя клиента; номер телефона клиента; дата регистрации; количество заказов; сумма всех выполненных заказов; 
-- сумма всех платежей от клиента; есть ли задолженность у клиента; выполняется ли сейчас заказ с этим 
-- клиентом (да/нет); дата последнего заказ клиента; количество заказов от клиента в текущем году. 

WITH client_stats AS ( -- статистика по клиентам
  SELECT 
    u.taxi_user_id,
    CONCAT(u.first_name, ' ', u.last_name) AS client_name,
    u.phone_number,
    u.registration_date,
    COUNT(DISTINCT o.taxi_order_id) AS total_orders, -- количество заказов
    COALESCE(SUM(
      CASE WHEN os.status_name = 'ride_completed' 
           THEN tt.trip_tariff * EXTRACT(EPOCH FROM (o.end_date - o.start_date))/60
           ELSE 0 
      END
    ), 0) AS total_completed_orders_sum, -- сумма выплаченная за выполненные заказы
    COALESCE((
      SELECT SUM(payment_sum) 
      FROM input_payment 
      WHERE taxi_user_id = u.taxi_user_id
    ), 0) AS total_payments, -- сколько выплатил суммарно 
    CASE WHEN u.debit > 0 THEN 'yes' ELSE 'no' END AS has_debt,
    MAX(o.start_date) AS last_order_date,
    MAX(CASE WHEN os.status_name IN ('driver_search', 'driver_has_been_found', 'ride_started') 
        THEN 1 ELSE 0 END) = 1 AS has_active_order, -- выполняется ли заказ сейчас
    SUM(CASE WHEN EXTRACT(YEAR FROM o.start_date) = EXTRACT(YEAR FROM CURRENT_DATE) THEN 1 ELSE 0 END) AS current_year_orders
  FROM taxi_user u
  LEFT JOIN taxi_order o ON u.taxi_user_id = o.client_id
  LEFT JOIN trip_type tt ON o.trip_type_id = tt.trip_type_id
  LEFT JOIN taxi_order_status os ON o.taxi_order_status_id = os.taxi_order_status_id
  WHERE u.role_id = (SELECT role_id FROM role WHERE role_name = 'client')
  GROUP BY u.taxi_user_id
)

SELECT -- основной запрос
  client_name AS "Client's name",
  phone_number AS "Client's phone number",
  TO_CHAR(registration_date, 'DD.MM.YYYY') AS "Registration date",
  total_orders AS "Number of orders",
  total_completed_orders_sum AS "The sum of all completed orders", -- сумма выплат за выполненные заказы
  total_payments AS "The amount of all payments", -- сумма всех выплат
  has_debt AS "Does the client have any debt",
  CASE WHEN has_active_order THEN 'yes' ELSE 'no' END AS "Is the order being completed now",
  CASE 
    WHEN last_order_date IS NOT NULL 
    THEN TO_CHAR(last_order_date, 'DD.MM.YYYY')
    ELSE 'no orders'
  END AS "Date of the client's last order",
  current_year_orders AS "The number of orders in the current year"
FROM client_stats
ORDER BY client_name \gx



-- 4) Четвертый запрос.
--
-- Получить отчет по выполняемым (в статусе: только создан, водитель найден, поездка начата) заказам в следующем виде:
-- Номер заказа, дата начала, ФИО клиента, статус, выполняющий водитель, автомобиль, число отказов, текущий тариф, 
-- текущая стоимость, пункт отправки, пункт назначения, ответственный диспетчер.

SELECT -- Основной запрос
    o.taxi_order_id AS "Order number",
    TO_CHAR(o.start_date, 'DD.MM.YYYY HH24:MI') AS "Start date",
    CONCAT(cu.first_name, ' ', cu.last_name) AS "Client's name",
    os.status_name AS "Status",
    CASE 
        WHEN o.driver_id IS NULL THEN 'not assigned'
        ELSE CONCAT(du.first_name, ' ', du.last_name) 
    END AS "Driver",
    CASE
        WHEN o.driver_id IS NULL THEN 'not assigned'
        ELSE car.car_brand_name
    END AS "Car",
    (SELECT COUNT(*) 
     FROM driver_rejection dr 
     WHERE dr.taxi_order_id = o.taxi_order_id) AS "Rejection count", -- Число отказов от этого заказа
    tt.trip_tariff AS "Current tariff",
    CASE
        WHEN o.end_date IS NOT NULL THEN 
            ROUND((tt.trip_tariff * EXTRACT(EPOCH FROM (o.end_date - o.start_date))/60)::numeric, 2)
        ELSE
            ROUND((tt.trip_tariff * EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - o.start_date))/60)::numeric, 2)
    END AS "Current price",
    o.start_point AS "Start point",
    o.end_point AS "End point",
    CONCAT(dis.first_name, ' ', dis.last_name) AS "Dispatcher"
FROM 
    taxi_order o
JOIN 
    taxi_user cu ON o.client_id = cu.taxi_user_id
LEFT JOIN 
    taxi_user du ON o.driver_id = du.taxi_user_id
LEFT JOIN
    contract c ON o.driver_id = c.taxi_user_id 
    AND CURRENT_TIMESTAMP BETWEEN c.start_date AND c.end_date
LEFT JOIN
    car ON c.car_registration_id = car.car_registration_id
JOIN 
    taxi_order_status os ON o.taxi_order_status_id = os.taxi_order_status_id
JOIN 
    trip_type tt ON o.trip_type_id = tt.trip_type_id
JOIN 
    taxi_user dis ON o.dispatcher_id = dis.taxi_user_id
WHERE 
    os.status_name IN ('just_created', 'driver_search', 'driver_has_been_found', 'ride_started')
ORDER BY 
    o.start_date DESC \gx

-- 5) Пятый запрос.
--
-- Получить статистику по отказам в виде:
-- Причина отказа; число отказов; дата последнего отказа; число разных водителей, 
-- указавших этот отказ; имя водитель и количество раз, для водителя, чаще всего 
-- указывавшего эту причину отказа; имя клиента и число раз для клиента, чаще всего 
-- получавшего эту причину отказа. Для этого запроса вывести план выполнения.

WITH rejection_stats AS ( -- статистика по отказам
  SELECT 
    r.reason,
    COUNT(*) AS rejection_count,
    MAX(r.date) AS last_rejection,
    COUNT(DISTINCT r.driver_id) AS unique_drivers,
    
    (SELECT CONCAT(u.first_name, ' ', u.last_name)
     FROM driver_rejection r2
     JOIN taxi_user u ON r2.driver_id = u.taxi_user_id
     WHERE r2.reason = r.reason
     GROUP BY u.taxi_user_id, u.first_name, u.last_name
     ORDER BY COUNT(*) DESC
     LIMIT 1) AS top_driver,
     
    (SELECT COUNT(*)
     FROM driver_rejection r2
     WHERE r2.reason = r.reason
     AND r2.driver_id = (SELECT r3.driver_id
                         FROM driver_rejection r3
                         JOIN taxi_user u ON r3.driver_id = u.taxi_user_id
                         WHERE r3.reason = r.reason
                         GROUP BY r3.driver_id, u.first_name, u.last_name
                         ORDER BY COUNT(*) DESC
                         LIMIT 1)) AS driver_count,
    
    (SELECT CONCAT(u.first_name, ' ', u.last_name)
     FROM driver_rejection r2
     JOIN taxi_order o ON r2.taxi_order_id = o.taxi_order_id
     JOIN taxi_user u ON o.client_id = u.taxi_user_id
     WHERE r2.reason = r.reason
     GROUP BY o.client_id, u.first_name, u.last_name
     ORDER BY COUNT(*) DESC
     LIMIT 1) AS top_client,
     
    (SELECT COUNT(*)
     FROM driver_rejection r2
     JOIN taxi_order o ON r2.taxi_order_id = o.taxi_order_id
     WHERE r2.reason = r.reason
     AND o.client_id = (SELECT o2.client_id
                       FROM driver_rejection r3
                       JOIN taxi_order o2 ON r3.taxi_order_id = o2.taxi_order_id
                       JOIN taxi_user u ON o2.client_id = u.taxi_user_id
                       WHERE r3.reason = r.reason
                       GROUP BY o2.client_id, u.first_name, u.last_name
                       ORDER BY COUNT(*) DESC
                       LIMIT 1)) AS client_count
  FROM driver_rejection r
  GROUP BY r.reason
)

SELECT -- основной запрос
  reason AS "Reason of rejection",
  rejection_count AS "Rejection rate",
  TO_CHAR(last_rejection, 'DD.MM.YYYY HH24:MI') AS "Date of last rejection",
  unique_drivers AS "Number of different drivers",
  top_driver AS "The driver (most often)",
  driver_count AS "Number rejections of the driver",
  top_client AS "The client (most often)",
  client_count AS "Number rejections of the client"
FROM rejection_stats
ORDER BY rejection_count DESC \gx
