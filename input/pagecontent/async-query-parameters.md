{% sqlToData async_params
	WITH raw_params AS (
		SELECT
		param.parent,
		MAX(CASE WHEN param.key = 'name' THEN atom END) AS param_name,
		MAX(CASE WHEN param.key = 'documentation' THEN atom END) AS param_doc,
		MAX(CASE WHEN param.key = 'type' THEN atom END) AS param_type,
		MAX(CASE WHEN param.key = 'min' THEN atom END) AS param_min,
		MAX(CASE WHEN param.key = 'max' THEN atom END) AS param_max
		FROM Resources,
			json_tree(Resources.Json, '$.parameter') AS param
		WHERE Resources.Id = 'async'
		GROUP BY param.parent
	)
	SELECT *,
	param_min || '..' || param_max AS cardinality,
	CASE
		WHEN instr(param_doc, char(10) || char(10)) > 0
		THEN substr(param_doc, instr(param_doc, char(10) || char(10)) + 2)
		ELSE param_doc
	END AS description
	FROM raw_params
	WHERE param_name IS NOT NULL
	ORDER BY parent
%}

<table class="table">
  <thead>
    <th>Parameter</th>
    <th>Cardinality</th>
    <th>Type</th>
    <th>Description</th>
  </thead>
  <tbody>
{% for p in async_params %}{% if p.param_name %}    <tr>
      <td><code>{{ p.param_name }}</code></td>
      <td>{{ p.cardinality }}</td>
      <td>{{ p.param_type }}</td>
      <td>{{ p.description | markdownify }}</td>
    </tr>
{% endif %}{% endfor %}  </tbody>
</table>
