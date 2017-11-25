$(document).foundation()

$(document).ready(function() {

  $('#instances').DataTable({
    'mark': true,
    'pageLength': 50,
    'columnDefs': [ {
      'targets'  : 'no-sort',
      'orderable': false,
    }]
  });

  $('a#toggle-tags').click(function(){
    $(this).parent().parent().children('.label.tag.other').toggle();
    if($(this).text() == 'All'){
      $(this).text('Filtered');
    } else {
      $(this).text('All');
    }
  });

  $('a#show-all-tags').click(function(){
    $('.label.tag.other').show();
    $('.label.toggle-link > a#toggle-tags').text('Filtered')
  });

  $('a#show-filtered-tags').click(function(){
    $('.label.tag.other').hide();
    $('.label.toggle-link > a#toggle-tags').text('All')
  });

})
