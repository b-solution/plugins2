function remove_order_fields (link) {
  // $(link).parents('.fields').fadeOut("slow");
  $(link).prev("input[type=hidden]").val("1")
  $(link).parents('.fields').hide();
  updateTotal();
  reorderLines();
}

function add_fields (link, association, content) {
  var new_id = new Date().getTime();
  var regexp = new RegExp("new_" + association, "g");
  $('#sortable tr.line').last().after(content.replace(regexp, new_id))
  $('#order_lines_attributes_' + new_id + '_description').focus();
  updateTotal();
}

function observeProductAutocompleteField(fieldId, url, select_url, options) {
  $(document).ready(function() {
    $('#'+fieldId).autocomplete($.extend({
      source: url,
      minLength: 0,
      search: function(){$('#'+fieldId).addClass('ajax-loading');},
      response: function(){$('#'+fieldId).removeClass('ajax-loading');},
      select: function( event, ui ) {
          $.ajax({
             url: select_url,
             type: 'POST',
             data: {id: ui.item.id}
          });
          return false;
      },
    }, options))
    // .focus(function(){$(this).autocomplete("search");})
    .data('ui-autocomplete')._renderItem = function( ul, item ) {
                              return $('<li>')
                                .append('<a>' + item.info + '</a>')
                                .appendTo( ul );
                            };
    $('#'+fieldId).addClass('autocomplete');
  });
}

function formatCurrency(num) {
    num = isNaN(num) || num === '' || num === null ? 0.00 : num;
    return parseFloat(num).toFixed(2);
}

function updateTotal(element) {

  var rows = $("#product_lines tr.line.fields:visible"); // skip the header row
  var amounts = $('#product_lines tr.line.fields:visible td.total');

  rows.each(function(index) {
    var qty_input = $("td.quantity input", this);
    var price_input = $("td.price input", this);
    var discount_input = $("td.discount input[type=\"text\"]", this);
    var tax_input = $("td.tax input[type=\"text\"]", this);

    var qty = qty_input.val();
    var price = price_input.val();
    var discount = discount_input.val();
    var amount = price * qty * (1 - discount/100);
    var tax = amount / 100 * tax_input.val();
    var subtotal = amount;
    subtotal += tax;

    tax = tax.toFixed(2); // limit to two decimal places
    amount = amount.toFixed(2);
    subtotal = subtotal.toFixed(2);

    $(this).children("td.total").html(amount)

    // $('#total_amount').html(amount); // output the values

  });

  var amttoal = 0;
  var vattotal = 0;
  var total = 0;

  amounts.each(function(){
      amttoal += parseFloat($(this).html())
  });

  $('#total_amount').html(amttoal.toFixed(2));

}

function updateLineFrom(url, product_id, element_id) {
  $.ajax({
    url: url,
    type: 'post',
    data: {id: product_id, element: element_id}
  });
}

function activateTextAreaResize(element) {
  $(element).keyup(function() {
    while($(element).outerHeight() < element.scrollHeight + parseFloat($(element).css("borderTopWidth")) + parseFloat($(element).css("borderBottomWidth")) && $(element).outerHeight() < 300) {
          $(element).height($(element).height()+15);
    };
  });
}

function reorderLines() {
  $('tr.sortable-line:visible').each(function(i, elem){
    $(elem).find('input.position').val(i + 1);
  });
}

$(function() {
  if ($('.product-lines').length)
  {

    var fixHelper = function(e, ui) {
      ui.children().each(function() {
        $(this).width($(this).width());
      });
      return ui;
    };

    $('.product-lines tbody#sortable').sortable({
      axis: 'y',
      opacity: 0.7,
      helper: fixHelper,
      stop: function(e,ui){reorderLines()}
    });
  }
});