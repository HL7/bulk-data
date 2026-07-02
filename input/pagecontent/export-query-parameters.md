{% sqlToData params
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
		WHERE Resources.Id = 'group-export'
		GROUP BY param.parent
	)
	SELECT *,
	param_min || '..' || param_max AS cardinality,
	CASE
		WHEN param_doc LIKE 'Support is required%' THEN 'required'
		WHEN param_doc LIKE 'Experimental%' THEN 'optional, experimental'
		ELSE 'optional'
	END AS data_provider_optionality,
	CASE
		WHEN param_doc LIKE '%, required for a Data Consumer%' THEN 'required'
		ELSE 'optional'
	END AS data_consumer_optionality,
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
    <th>Optionality for Data Provider</th>
    <th>Optionality for Data Consumer</th>
    <th>Cardinality</th>
    <th>Type</th>
    <th>Description</th>
  </thead>
  <tbody>
{% for p in params %}{% if p.param_name %}    <tr>
      <td><code>{{ p.param_name }}</code></td>
      <td><span class="label label-{% if p.data_provider_optionality == 'required' %}success{% else %}info{% endif %}">{{ p.data_provider_optionality }}</span></td>
      <td><span class="label label-{% if p.data_consumer_optionality == 'required' %}success{% else %}info{% endif %}">{{ p.data_consumer_optionality }}</span></td>
      <td>{{ p.cardinality }}</td>
      <td>{{ p.param_type }}</td>
      <td>{{ p.description | markdownify }}</td>
    </tr>
{% endif %}{% endfor %}  </tbody>
</table>
