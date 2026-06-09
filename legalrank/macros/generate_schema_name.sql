{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- if custom_schema_name is not none -%}
        {{ custom_schema_name }}
    {%- elif node.resource_type == 'seed' -%}
        {{ node.config.schema | upper }}
    {%- elif node.package_name == 'elementary' -%}
        ELEMENTARY
    {%- else -%}
        {{ node.fqn[1] }}
    {%- endif -%}
{%- endmacro %}
