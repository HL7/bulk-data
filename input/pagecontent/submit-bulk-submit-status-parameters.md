{% sqlToData bulk_submit_status_params
	WITH params AS (
		SELECT
		CAST(param.key AS integer) AS param_ordinal,
		NULL AS part_ordinal,
		0 AS level,
		0 AS indent_px,
		json_extract(param.value, '$.name') AS param_name,
		CAST(json_extract(param.value, '$.min') AS text) || '..' || json_extract(param.value, '$.max') AS cardinality,
		COALESCE(json_extract(param.value, '$.type'), 'part') AS param_type,
		json_extract(param.value, '$.documentation') AS description
		FROM Resources,
			json_each(Resources.Json, '$.parameter') AS param
		WHERE Resources.Id = 'bulk-submit-status'

		UNION ALL

		SELECT
		CAST(param.key AS integer) AS param_ordinal,
		CAST(part.key AS integer) AS part_ordinal,
		1 AS level,
		18 AS indent_px,
		json_extract(part.value, '$.name') AS param_name,
		CAST(json_extract(part.value, '$.min') AS text) || '..' || json_extract(part.value, '$.max') AS cardinality,
		COALESCE(json_extract(part.value, '$.type'), 'part') AS param_type,
		json_extract(part.value, '$.documentation') AS description
		FROM Resources,
			json_each(Resources.Json, '$.parameter') AS param,
			json_each(param.value, '$.part') AS part
		WHERE Resources.Id = 'bulk-submit-status'
	)
	SELECT *
	FROM params
	ORDER BY param_ordinal, level, part_ordinal
%}

<table class="table">
  <thead>
    <th>Parameter</th>
    <th>Cardinality</th>
    <th>Type</th>
    <th>Description</th>
  </thead>
  <tbody>
{% for p in bulk_submit_status_params %}    <tr>
      <td><span style="padding-left: {{ p.indent_px }}px; display: inline-block;">{% if p.level > 0 %}&#8627; {% endif %}<code>{{ p.param_name }}</code></span></td>
      <td>{{ p.cardinality }}</td>
      <td>{{ p.param_type }}</td>
      <td>{{ p.description | markdownify }}</td>
    </tr>
{% endfor %}  </tbody>
</table>
