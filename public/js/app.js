$(document).foundation()

$(document).ready(function() {

  $('#instances').DataTable({
    "pageLength": 50
  });

  $("a#toggle-tags").click(function(){
    $(this).parent().children(".label.hidden").toggle();
  });

  $('#user_change_password').submit(function() {
    var new_password = $.trim($('input[name="new_password"]').val())
    var new_password_confirmation = $.trim($('input[name="new_password_confirmation"]').val())

    if (new_password == '') {
      alert('Password cannot be empty or blank')
      return false
    }

    if (new_password != new_password_confirmation) {
      alert('New password and confirmation do not match')
      return false
    }
  })

  $('#user_delete').submit(function() {
    var admin_password = $.trim($('input[name="admin_password"]').val())
    if (admin_password == '') {
      alert('Password cannot be empty or blank')
      return false
    }
    return confirm('Are you sure you want to delete this user?')
  })
})
