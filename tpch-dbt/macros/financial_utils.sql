-- harga awal * (1-diskon)

{% macro calculate_discounted_price(price, discount) %}
    {{ price }} * (1 - {{ discount }})
{% endmacro %}