{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- if custom_schema_name is not none -%}
        {{ custom_schema_name }}
    {%- else -%}
        {{ node.fqn[1] }}
    {%- endif -%}
{%- endmacro %}