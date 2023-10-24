
# Change the mail address of a Microsoft Bookings calendar
# For my post at https://blog.topedia.com/?p=31934
# 
# PowerShell module Microsoft.Graph.Authentication is required > https://www.powershellgallery.com/packages/Microsoft.Graph.Authentication

Connect-MgGraph -Scopes Bookings.Manage.All,User.ReadWrite.All

$CurrentBookingsCalenderName = "Topedia Blookings"
$NewBookingsCalenderName = "Topedia Bookings"
$NewBookingsMailAddress = "TopediaBookings@demo1.tam365.com"

# Receive the current Bookings calendar
$Url = "https://graph.microsoft.com/v1.0/solutions/bookingBusinesses?query=$CurrentBookingsCalenderName"
$Result = Invoke-MgGraphRequest -Method GET -Uri $Url -ContentType "application/json" 
$Result.value
$BookingsCalendarID = $Result.value.id

# Rename the Bookings calender (just the display name)
$Body = 
@"
{ "displayName": "$NewBookingsCalenderName" }
"@

$Url = "https://graph.microsoft.com/v1.0/solutions/bookingBusinesses/$BookingsCalendarID"
Invoke-MgGraphRequest -Method PATCH -Uri $Url -Body $Body -ContentType "application/json" 

# Load the Bookings calender
$Url = "https://graph.microsoft.com/v1.0/solutions/bookingBusinesses/$BookingsCalendarID"
$BookingsCalendar = Invoke-MgGraphRequest -Method GET -Uri $Url -ContentType "application/json" 
$BookingsCalendar

# Load the user account from the Booking calendar
$Url = "https://graph.microsoft.com/beta/users/$BookingsCalendarID"
$BookingsUserAccount = Invoke-MgGraphRequest -Method GET -Uri $Url -ContentType "application/json" 
$BookingsUserAccount | select userPrincipalName,mail,id | fl

# Update the UserPrincipalName and mail address from the Bookings calendar
$Body = 
@"
{ "userPrincipalName": "$NewBookingsMailAddress",
  "mail": "$NewBookingsMailAddress"
}
"@

$Url = ("https://graph.microsoft.com/v1.0/users/" + $BookingsUserAccount.id)
Invoke-MgGraphRequest -Method PATCH -Uri $Url -Body $Body -ContentType "application/json" 

# Validate the updated Bookings calendar
$Url = "https://graph.microsoft.com/v1.0/solutions/bookingBusinesses/$NewBookingsMailAddress"
$BookingsCalendar = Invoke-MgGraphRequest -Method GET -Uri $Url -ContentType "application/json" 
$BookingsCalendar.GetEnumerator() | ?{$_.name -eq "displayName" -or $_.Name -eq "id" }

# Unplish and publish the Bookings calendar (to update the public url of the calendar)
$Url = "https://graph.microsoft.com/v1.0/solutions/bookingBusinesses/$NewBookingsMailAddress/unpublish"
Invoke-MgGraphRequest -Method POST -Uri $Url -ContentType "application/json" 

$Url = "https://graph.microsoft.com/v1.0/solutions/bookingBusinesses/$NewBookingsMailAddress/publish"
Invoke-MgGraphRequest -Method POST -Uri $Url -ContentType "application/json" 

# Show the updated Bookings calendar url
$BookingsCalendar.publicUrl



