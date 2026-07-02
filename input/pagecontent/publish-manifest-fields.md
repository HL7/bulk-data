{% sqlToData publish_manifest_fields
	WITH snapshot AS (
		SELECT
		CAST(element.key AS integer) AS ordinal,
		json_extract(element.value, '$.path') AS full_path,
		replace(json_extract(element.value, '$.path'), 'BulkPublishManifest.', '') AS rel_path,
		json_extract(element.value, '$.definition') AS el_def,
		CAST(json_extract(element.value, '$.min') AS text) AS el_min,
		json_extract(element.value, '$.max') AS el_max,
		json_extract(element.value, '$.type[0].code') AS el_type
		FROM Resources,
			json_each(Resources.Json, '$.snapshot.element') AS element
		WHERE Resources.Id = 'BulkPublishManifest'
	),
	filtered AS (
		SELECT
		ordinal,
		full_path,
		rel_path,
		el_def,
		el_min,
		el_max,
		COALESCE(el_type, '') AS el_type,
		LENGTH(rel_path) - LENGTH(REPLACE(rel_path, '.', '')) AS level,
		CASE WHEN el_min = '1' THEN 0 ELSE 1 END AS required_sort,
		CASE
			WHEN instr(rel_path, '.') > 0 THEN substr(rel_path, 1, instr(rel_path, '.') - 1)
			ELSE rel_path
		END AS seg1,
		CASE
			WHEN LENGTH(rel_path) - LENGTH(REPLACE(rel_path, '.', '')) >= 1 THEN
				CASE
					WHEN instr(substr(rel_path, instr(rel_path, '.') + 1), '.') > 0 THEN
						substr(
							substr(rel_path, instr(rel_path, '.') + 1),
							1,
							instr(substr(rel_path, instr(rel_path, '.') + 1), '.') - 1
						)
					ELSE substr(rel_path, instr(rel_path, '.') + 1)
				END
			ELSE NULL
		END AS seg2,
		CASE
			WHEN LENGTH(rel_path) - LENGTH(REPLACE(rel_path, '.', '')) >= 2 THEN
				substr(
					rel_path,
					instr(rel_path, '.') + instr(substr(rel_path, instr(rel_path, '.') + 1), '.') + 1
				)
			ELSE NULL
		END AS seg3
		FROM snapshot
		WHERE rel_path IS NOT NULL
		AND rel_path != 'BulkPublishManifest'
		AND rel_path != ''
		AND rel_path NOT LIKE '%.id'
		AND rel_path NOT LIKE '%.extension'
		AND rel_path NOT LIKE '%.modifierExtension'
		AND rel_path NOT IN ('id', 'extension', 'modifierExtension')
	),
	enriched AS (
		SELECT
		f.*,
		CASE
			WHEN EXISTS (
				SELECT 1
				FROM filtered excluded
				WHERE excluded.el_min = '0'
				AND excluded.el_max = '0'
				AND (
					f.rel_path = excluded.rel_path
					OR f.rel_path LIKE excluded.rel_path || '.%'
				)
			) THEN 1
			ELSE 0
		END AS omit_from_table,
		CASE f.seg1
			WHEN 'manifestType' THEN 1
			WHEN 'transactionTime' THEN 2
			WHEN 'epochStartTime' THEN 3
			WHEN 'updateCadence' THEN 4
			WHEN 'requiresAccessToken' THEN 5
			WHEN 'outputFormat' THEN 6
			WHEN 'outputOrganizedBy' THEN 7
			WHEN 'outputOrganizedByDetail' THEN 8
			WHEN 'output' THEN 9
			WHEN 'deleted' THEN 10
			WHEN 'outcome' THEN 11
			WHEN 'link' THEN 12
			ELSE 999
		END AS top_sort,
		top.required_sort AS top_required_sort,
		top.ordinal AS top_ordinal,
		child.required_sort AS child_required_sort,
		child.ordinal AS child_ordinal
		FROM filtered f
		LEFT JOIN filtered top
			ON top.rel_path = f.seg1
			AND top.level = 0
		LEFT JOIN filtered child
			ON child.rel_path = CASE
				WHEN f.seg2 IS NOT NULL THEN f.seg1 || '.' || f.seg2
				ELSE NULL
			END
	)
	SELECT
	CASE
		WHEN level = 0 THEN rel_path
		WHEN level = 1 THEN seg2
		ELSE seg3
	END AS field_name,
	level,
	level * 18 AS indent_px,
	el_type AS field_type,
	el_min || '..' || el_max AS cardinality,
	el_def AS description
	FROM enriched
	WHERE omit_from_table = 0
	ORDER BY
		top_sort,
		CASE WHEN level = 0 THEN 0 ELSE 1 END,
		CASE WHEN level = 0 THEN 0 ELSE child_required_sort END,
		CASE WHEN level = 0 THEN 0 ELSE child_ordinal END,
		CASE WHEN level < 2 THEN 0 ELSE 1 END,
		required_sort,
		ordinal
%}

<table class="table">
  <thead>
    <th>Field</th>
    <th>Cardinality</th>
    <th>Type</th>
    <th>Description</th>
  </thead>
  <tbody>
{% for f in publish_manifest_fields %}    <tr>
      <td><span style="padding-left: {{ f.indent_px }}px; display: inline-block;">{% if f.level > 0 %}&#8627; {% endif %}<code>{{ f.field_name }}</code></span></td>
      <td>{{ f.cardinality }}</td>
      <td>{{ f.field_type }}</td>
      <td>{{ f.description | markdownify }}</td>
    </tr>
{% endfor %}  </tbody>
</table>
