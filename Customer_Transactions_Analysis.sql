-- ФИНАЛЬНЫЙ ПРОЕКТ ACADEMICA
-- SQL-анализ клиентских транзакций
-- Период: 01.06.2015 - 31.05.2016

USE final_project;


  # Задание №1. Находим клиентов с непрерывной историей покупок
  
  SELECT
    COUNT(*) AS regular_customers
FROM (
    SELECT
        ID_client
    FROM final_project.transactions_final
    WHERE date_new >= '2015-06-01'
      AND date_new < '2016-06-01'
    GROUP BY ID_client
    HAVING COUNT(
        DISTINCT DATE_FORMAT(date_new, '%Y-%m')
    ) = 12
) AS regular;
# Задание №1. Рассчитываем показатели по 82 клиентам

SELECT
    ID_client,
    COUNT(DISTINCT Id_check) AS total_operations,
    ROUND(SUM(Sum_payment), 2) AS total_payment,
    ROUND(
        SUM(Sum_payment) /
        NULLIF(COUNT(DISTINCT Id_check), 0), 2
    ) AS avg_check,
    ROUND(
        SUM(Sum_payment) / 12, 2
    ) AS avg_monthly_payment

FROM final_project.transactions_final

WHERE date_new >= '2015-06-01'
  AND date_new < '2016-06-01'

GROUP BY ID_client

HAVING COUNT(
    DISTINCT DATE_FORMAT(date_new, '%Y-%m')
) = 12

ORDER BY total_payment DESC;

SELECT
    COUNT(DISTINCT Id_check) AS unique_checks,
    COUNT(DISTINCT CONCAT(
        ID_client, '-', Id_check
    )) AS client_check_pairs,
    COUNT(DISTINCT CONCAT(
        DATE_FORMAT(date_new, '%Y-%m'),
        '-', Id_check
    )) AS month_check_pairs
FROM final_project.transactions_final
WHERE date_new >= '2015-06-01'
  AND date_new < '2016-06-01';
  
  # В ходе анализа выявлено 82 клиента с непрерывной историей покупок за 12 месяцев. Отдельно обнаружен клиент ID 16052 с аномально высоким количеством операций — 6 677 уникальных чеков. Проверка подтвердила уникальность идентификаторов чеков. Клиент сохранён в анализе, поскольку ошибка в данных не доказана. 
  # Для дальнейшей интерпретации рекомендуется сравнивать показатели с учётом и без учёта данного клиента.
  
  # Задание 2
# средняя сумма чека в месяц;
# среднее количество операций в месяц;
# среднее количество клиентов, которые совершали операции;
# долю от общего количества операций за год и долю в месяц от общей суммы операций;
# вывести % соотношение M/F/NA в каждом месяце с их долей затрат;

SELECT
    DATE_FORMAT(date_new, '%Y-%m') AS month,

    COUNT(DISTINCT Id_check) AS operations_count,

    COUNT(DISTINCT ID_client) AS active_clients,

    ROUND(SUM(Sum_payment), 2) AS total_payment,

    ROUND(
        SUM(Sum_payment) /
        NULLIF(COUNT(DISTINCT Id_check), 0),
        2
    ) AS avg_check,

    ROUND(
        COUNT(DISTINCT Id_check) * 100.0 /
        SUM(COUNT(DISTINCT Id_check)) OVER (),
        2
    ) AS operations_share_pct,

    ROUND(
        SUM(Sum_payment) * 100.0 /
        SUM(SUM(Sum_payment)) OVER (),
        2
    ) AS payment_share_pct

FROM final_project.transactions_final

WHERE date_new >= '2015-06-01'
  AND date_new < '2016-06-01'

GROUP BY DATE_FORMAT(date_new, '%Y-%m')

ORDER BY month;  # a. средняя сумма чека в месяц;

SELECT
    COUNT(DISTINCT Id_check) AS total_operations,
    COUNT(DISTINCT DATE_FORMAT(date_new, '%Y-%m'))
        AS months_count,
    ROUND(
        COUNT(DISTINCT Id_check) / 12,
        2
    ) AS avg_operations_per_month

FROM final_project.transactions_final

WHERE date_new >= '2015-06-01'
  AND date_new < '2016-06-01'; # b. среднее количество операций в месяц;

SELECT
    ROUND(AVG(monthly_clients), 2)
        AS avg_active_clients_per_month
FROM (
    SELECT
        DATE_FORMAT(date_new, '%Y-%m') AS month,
        COUNT(DISTINCT ID_client) AS monthly_clients
    FROM final_project.transactions_final
    WHERE date_new >= '2015-06-01'
      AND date_new < '2016-06-01'
    GROUP BY DATE_FORMAT(date_new, '%Y-%m')
) AS monthly_data;  # c. среднее количество клиентов, которые совершали операции;

WITH monthly_stats AS (
    SELECT
        DATE_FORMAT(date_new, '%Y-%m') AS month,
        COUNT(DISTINCT Id_check) AS operations_count,
        SUM(Sum_payment) AS total_payment
    FROM final_project.transactions_final
    WHERE date_new >= '2015-06-01'
      AND date_new < '2016-06-01'
    GROUP BY DATE_FORMAT(date_new, '%Y-%m')
)

SELECT
    month,
    operations_count,
    ROUND(
        operations_count * 100.0 /
        SUM(operations_count) OVER (), 2
    ) AS operations_share_pct,
    ROUND(total_payment, 2) AS total_payment,
    ROUND(
        total_payment * 100.0 /
        SUM(total_payment) OVER (), 2
    ) AS payment_share_pct
FROM monthly_stats
ORDER BY month; # d. доля от общего количества операций за год и доля в месяц от общей суммы операций;

WITH gender_stats AS (
    SELECT
        DATE_FORMAT(t.date_new, '%Y-%m') AS month,

        CASE
            WHEN UPPER(TRIM(c.Gender)) IN ('M', 'MALE')
                THEN 'M'
            WHEN UPPER(TRIM(c.Gender)) IN ('F', 'FEMALE')
                THEN 'F'
            ELSE 'NA'
        END AS gender_group,

        COUNT(DISTINCT t.ID_client) AS clients_count,
        SUM(t.Sum_payment) AS total_payment

    FROM final_project.transactions_final t

    LEFT JOIN final_project.customer_final c
        ON t.ID_client = c.Id_client

    WHERE t.date_new >= '2015-06-01'
      AND t.date_new < '2016-06-01'

    GROUP BY
        DATE_FORMAT(t.date_new, '%Y-%m'),
        gender_group
)

SELECT
    month,
    gender_group,
    clients_count,

    ROUND(
        clients_count * 100.0 /
        SUM(clients_count) OVER (PARTITION BY month),
        2
    ) AS clients_share_pct,

    ROUND(total_payment, 2) AS total_payment,

    ROUND(
        total_payment * 100.0 /
        SUM(total_payment) OVER (PARTITION BY month),
        2
    ) AS payment_share_pct

FROM gender_stats

ORDER BY
    month,
    FIELD(gender_group, 'M', 'F', 'NA'); # e.  % соотношение M/F/NA в каждом месяце с их долей затрат;


# Задание 3. возрастные группы клиентов с шагом 10 лет и отдельно клиентов, у которых нет данной информации, 
# с параметрами сумма и количество операций за весь период, и поквартально - средние показатели и %.

SELECT
    COUNT(*) AS total_customers,
    COUNT(DISTINCT Id_client) AS unique_customers,
    SUM(
        Age IS NULL OR TRIM(Age) = ''
    ) AS missing_age,
    SUM(
        UPPER(TRIM(Age)) IN ('NA', 'NAN', 'NULL')
    ) AS text_missing_age,
    MIN(
        CASE
            WHEN TRIM(Age) REGEXP '^[0-9]+$'
            THEN CAST(Age AS UNSIGNED)
        END
    ) AS min_age,
    MAX(
        CASE
            WHEN TRIM(Age) REGEXP '^[0-9]+$'
            THEN CAST(Age AS UNSIGNED)
        END
    ) AS max_age
FROM final_project.customer_final;


SELECT
    c.Id_client,
    c.Age,
    c.Gender,
    COUNT(DISTINCT t.Id_check) AS operations_count,
    ROUND(SUM(t.Sum_payment), 2) AS total_payment
FROM final_project.customer_final c
LEFT JOIN final_project.transactions_final t
    ON c.Id_client = t.ID_client
   AND t.date_new >= '2015-06-01'
   AND t.date_new < '2016-06-01'
WHERE TRIM(c.Age) = '1'
GROUP BY c.Id_client, c.Age, c.Gender;  # возраст 1 год требует проверки первичного источника. 
# Можно отдельно отнести сомнительные возраста к категории «Некорректный возраст».

SELECT
    Age,
    COUNT(*) AS customers_count
FROM final_project.customer_final
WHERE TRIM(Age) REGEXP '^[0-9]+$'
  AND CAST(Age AS UNSIGNED) < 18
GROUP BY Age
ORDER BY CAST(Age AS UNSIGNED); # клиентов младше 18 лет и какие именно возраста встречаются.


WITH quarterly_stats AS (
    SELECT
        YEAR(t.date_new) AS yr,
        QUARTER(t.date_new) AS qtr,

        CASE
            WHEN c.Age IS NULL
              OR TRIM(c.Age) = ''
                THEN 'Не указан'
            ELSE CONCAT(
                FLOOR(CAST(c.Age AS UNSIGNED) / 10) * 10,
                '-',
                FLOOR(CAST(c.Age AS UNSIGNED) / 10) * 10 + 9
            )
        END AS age_group,

        COUNT(DISTINCT t.Id_check) AS operations_count,
        SUM(t.Sum_payment) AS total_payment

    FROM final_project.transactions_final t
    LEFT JOIN final_project.customer_final c
        ON t.ID_client = c.Id_client

    WHERE t.date_new >= '2015-06-01'
      AND t.date_new < '2016-06-01'

    GROUP BY yr, qtr, age_group
)

SELECT
    CONCAT(yr, '-Q', qtr) AS quarter,
    age_group,
    operations_count,
    ROUND(total_payment, 2) AS total_payment,

    ROUND(
        total_payment / NULLIF(operations_count, 0),
        2
    ) AS avg_check,

    ROUND(
        operations_count /
        CASE
            WHEN yr = 2015 AND qtr = 2 THEN 1
            WHEN yr = 2016 AND qtr = 2 THEN 2
            ELSE 3
        END, 2
    ) AS avg_monthly_operations,

    ROUND(
        total_payment /
        CASE
            WHEN yr = 2015 AND qtr = 2 THEN 1
            WHEN yr = 2016 AND qtr = 2 THEN 2
            ELSE 3
        END, 2
    ) AS avg_monthly_payment,

    ROUND(
        operations_count * 100.0 /
        SUM(operations_count) OVER (PARTITION BY yr, qtr),
        2
    ) AS operations_share_pct,

    ROUND(
        total_payment * 100.0 /
        SUM(total_payment) OVER (PARTITION BY yr, qtr),
        2
    ) AS payment_share_pct

FROM quarterly_stats
ORDER BY yr, qtr, age_group; # поквартальные показатели


WITH age_stats AS (
    SELECT
        CASE
            WHEN c.Age IS NULL
              OR TRIM(c.Age) = ''
              OR UPPER(TRIM(c.Age)) IN ('NA', 'NAN', 'NULL')
                THEN 'Не указан'
            ELSE CONCAT(
                FLOOR(CAST(c.Age AS UNSIGNED) / 10) * 10,
                '-',
                FLOOR(CAST(c.Age AS UNSIGNED) / 10) * 10 + 9
            )
        END AS age_group,

        COUNT(DISTINCT t.Id_check) AS operations_count,
        SUM(t.Sum_payment) AS total_payment

    FROM final_project.transactions_final t

    LEFT JOIN final_project.customer_final c
        ON t.ID_client = c.Id_client

    WHERE t.date_new >= '2015-06-01'
      AND t.date_new < '2016-06-01'

    GROUP BY age_group
)

SELECT
    age_group,
    operations_count,
    ROUND(total_payment, 2) AS total_payment,

    ROUND(
        total_payment / NULLIF(operations_count, 0),
        2
    ) AS avg_check,

    ROUND(
        operations_count / 12, 2
    ) AS avg_monthly_operations,

    ROUND(
        total_payment / 12, 2
    ) AS avg_monthly_payment,

    ROUND(
        operations_count * 100.0 /
        SUM(operations_count) OVER (),
        2
    ) AS operations_share_pct,

    ROUND(
        total_payment * 100.0 /
        SUM(total_payment) OVER (),
        2
    ) AS payment_share_pct

FROM age_stats
ORDER BY
    CASE WHEN age_group = 'Не указан' THEN 1 ELSE 0 END,
    CAST(SUBSTRING_INDEX(age_group, '-', 1) AS UNSIGNED); # показатели за весь период
    
    
/* АНАЛИТИЧЕСКОЕ ЗАКЛЮЧЕНИЕ

SQL-анализ клиентских транзакций за 2015–2016 годы

1. Цель исследования

Проанализировать покупательскую активность клиентов, выявить постоянных покупателей, исследовать динамику операций и сумм покупок, а также определить особенности поведения клиентов в зависимости от пола и возраста.

Период исследования: 1 июня 2015 года — 31 мая 2016 года включительно.

Инструмент: MySQL Workbench, SQL.

2. Подготовка и проверка данных

В базу данных final_project загружены две таблицы:

customer_final — 2 429 клиентов;

transactions_final — 419 122 строки товарных операций, включая данные за 1 июня 2016 года.

При подготовке данных были исправлены ошибки преобразования денежных сумм, приведены даты к типу DATE и проверена уникальность идентификаторов чеков.

Анализ выявил, что один чек может содержать несколько товарных строк. Поэтому количество покупок рассчитывалось по уникальным идентификаторам Id_check, а средний чек — как отношение общей суммы покупок к количеству уникальных чеков.

Также установлено, что все операции датированы первым числом месяца. Это позволяет анализировать помесячную активность, но не позволяет достоверно исследовать поведение покупателей по дням.

3. Постоянные клиенты

Выявлено 82 клиента, совершавших покупки каждый месяц на протяжении всего анализируемого года без пропусков.

Для каждого клиента рассчитаны количество уникальных чеков, общая сумма покупок, средний чек и среднемесячная сумма покупок.

Отдельно выделяется клиент 16052:

6 677 уникальных чеков;

543 153,55 — общая сумма покупок;

81,35 — средний чек;

45 262,80 — среднемесячная сумма покупок.

Такая высокая активность существенно отличается от показателей остальных рассмотренных клиентов. Однако проверка подтвердила уникальность идентификаторов чеков, поэтому оснований исключать операции из анализа нет.

Рекомендуется дополнительно выяснить характер данного клиента и оценить влияние его активности на агрегированные показатели.

4. Помесячная динамика покупок

Среднее количество уникальных активных клиентов составляет 965,17 в месяц.

Для каждого месяца рассчитаны количество уникальных чеков, активных клиентов, общая сумма покупок, средний чек, доля операций и доля суммы покупок относительно годовых показателей.

В июне 2015 года зафиксирована существенно более низкая активность — 316 чеков против 2 929 в июле. Это может отражать особенности формирования исходного массива данных и требует проверки полноты первого месяца.

5. Гендерная структура покупателей

Проведён анализ категорий M, F и NA с расчётом их долей среди активных клиентов и в общей сумме покупок каждого месяца.

В июне 2015 года женщины составляли 65,63% активных клиентов, мужчины — 31,25%, клиенты без указанного пола — 3,13%.

В том же месяце сумма покупок женщин составила 21 830,53, мужчин — 7 617,94, категории NA — 652,69.

В июле женщины также обеспечили наибольшую долю суммы покупок — 73,27%.

Полученные данные указывают на необходимость учитывать гендерную структуру при исследовании клиентских сегментов, не распространяя выводы отдельных месяцев автоматически на весь год.

6. Возрастная структура покупателей

По результатам годового анализа наибольшую долю операций обеспечивают клиенты возрастных групп 60–69 лет (26,01%), 30–39 лет (19,45%) и 20–29 лет (19,31%). Необычно высокая активность старшей возрастной группы требует дополнительной проверки структуры клиентских данных.

7. Качество данных и ограничения анализа

Выявлены следующие особенности:

Неполная информация о возрасте: 35 из 2 429 клиентов не имеют указанного возраста.

Необычно низкие значения возраста, включая 1 год у восьми клиентов.

Аномально высокая покупательская активность отдельных клиентов.

Все даты транзакций представлены первым числом соответствующего месяца.

Возрастные и поведенческие аномалии сохранены в анализе, поскольку их ошибочность не доказана. При использовании результатов для бизнес-решений необходимо проводить дополнительную проверку таких записей.

8. Бизнес-рекомендации

Развивать удержание клиентов. Исследовать поведение 82 постоянных покупателей, определить наиболее ценные клиентские сегменты и разработать предложения для повышения регулярности покупок.

Контролировать динамику продаж. Использовать помесячные показатели количества чеков, среднего чека и суммы покупок для выявления изменений спроса.

Развивать сегментную аналитику. Анализировать расходы по возрасту и полу, учитывая достаточность и качество данных.

Повысить качество данных. Внедрить регулярную проверку полноты возраста, корректности идентификаторов и аномальных значений.

Проверять выбросы отдельно. Оценивать влияние наиболее активных клиентов на средние показатели, не исключая их автоматически.

Итоговый вывод

SQL-анализ позволил выявить постоянных покупателей, рассчитать ключевые показатели покупательской активности и оценить различия между клиентскими сегментами.

Исследование показало, что для достоверной оценки клиентского поведения необходимо сочетать финансовые метрики с проверкой качества исходных данных. Полученные результаты могут использоваться для развития программ удержания, клиентской сегментации и регулярного мониторинга продаж.
*/

