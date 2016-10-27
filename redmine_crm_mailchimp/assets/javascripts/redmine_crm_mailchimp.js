$(function(){
  $('body').on('click', '#show-add-to-list-form', function(){
    $('#add-to-list-form').show();
  })
  if ( ($('.mailchimp-settings #settings_api_key').length) )
  {
    testMailchimpAPI = function(){
      val = $('.mailchimp-settings #settings_api_key').val();
      if (val) {
        $.ajax('/mailchimp_memberships/test_api?key=' + val, {
          success: function(data){
            if(data.success)
            {
              $('#api-test-success').show()
              $('#api-test-failure').hide()
            }
            else
            {
              $('#api-test-success').hide()
              $('#api-test-failure').show()
            }
          }
        })
      }
    }

    $('.mailchimp-settings #settings_api_key').bind('keyup', testMailchimpAPI)
    if ($('.mailchimp-settings #settings_api_key').is(':visible'))
    {
      testMailchimpAPI()
    }
  }
})

function loadMailchimpTabIfNeeded(contactId, projectId){
  $.ajax('/mailchimp/lists/' + projectId + '/' + contactId);
  $.ajax('/mailchimp/campaigns/' + projectId + '/' + contactId)
}

function removeOptionsAlreadySelectedElsewhere(select, evenSelected)
{
  select.find('option').each(function(i, elem){
    $(elem).removeAttr('style');
    if ( !$(elem).attr('selected') || evenSelected )
    {
      val = $(elem).attr('value');
      if ($('select.mailchimp-id option[value=' + val + ']:selected').length)
      {
        if (($('option[value=' + val + '][selected]').get(0) != elem) || ($('option[value=' + val + '][selected]').length > 1))
        {
          $(elem).hide()
        }
      }
    }
  });
}

function setMailchimpListOptions() {
  $('select.mailchimp-id').each(function(i, elem){
    removeOptionsAlreadySelectedElsewhere($(elem))
  });
}

function showMailchimpListAssignmentForm() {
  exitAtOnce = false
  $('#mailchimp_list_assignments select').each(function(i, elem){
    if (!$(elem).val()) {
      exitAtOnce = true;
    }
  });
  if (exitAtOnce) return;

  lastRow = $('#mailchimp_list_assignments tbody tr:last-child')
  form = $(mailchimpAssignmentFormHtml).insertBefore(lastRow);
  mailchimpIdSelect = form.find('.mailchimp-id');
  mailchimpIdSelect.change(function(){ setMailchimpListOptions() })
  removeOptionsAlreadySelectedElsewhere(mailchimpIdSelect, true);
  if (mailchimpIdSelect.find('option:not([style])').length == 0) {// Only empty value without alternatives
    form.remove();
  }
}

$(function(){
  if ($('#add-new-assignment-button').length) {
    $('#add-new-assignment-button').click(showMailchimpListAssignmentForm);
  }
})

function mailchimpSyncHandler(e) {
  tr = $(e.target).closest('tr');
  contactQueryId = tr.find('.contact-query-id').val();
  mailchimpId = tr.find('.mailchimp-id').val();
  $.ajax('/mailchimp/sync/' + contactQueryId + '/with/' + mailchimpId, {
    success: function(){
      tr.find('.mailchimp-sync').removeClass('icon-sync').addClass('icon-sync-ok');
    }
  });
}

function mailchimpDeleteHandler(e) {
  tr = $(e.target).closest('tr');
  if (confirm(mailchimpDeleteConfirmText)) {
    tr.remove();
  }
  setMailchimpListOptions();
}

function clearInvalidRows(){
  $('#mailchimp_list_assignments select').each(function(i, elem){
    if (!$(elem).val())
      $(elem).closest('tr').remove()
  })
  $('#mailchimp_list_assignments tbody tr').each(function(i, elem){
    $(elem).data('position', i)
  })
  $('#mailchimp_list_assignments tbody tr').each(function(i, elem){
    tr = $(elem)
    contactQueryId = tr.find('select.contact-query-id').val()
    mailchimpId = tr.find('select.mailchimp-id').val()
    if (contactQueryId && mailchimpId)
    {
      $('#mailchimp_list_assignments tbody tr').each(function(j, candidate){
        trCandidate = $(candidate)

        candidateContactQueryId = trCandidate.find('select.contact-query-id').val()
        candidateMailchimpId = trCandidate.find('select.mailchimp-id').val()
        if ( tr.data('position') && (candidateMailchimpId == mailchimpId) && (candidateContactQueryId == contactQueryId) && (trCandidate.data('position') != tr.data('position')) )
        {
          trCandidate.remove()
        }
      })
    }
  })
}

$(function(){
  $('body').on('click', '.mailchimp-sync', mailchimpSyncHandler);
  $('body').on('click', '.mailchimp-delete', mailchimpDeleteHandler);
  $('body').on('change', 'select.mailchimp-id', setMailchimpListOptions);
  $('#tab-content-sync').closest('form').on('submit', clearInvalidRows);
  setMailchimpListOptions();
})
