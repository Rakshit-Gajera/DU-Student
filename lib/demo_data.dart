/// Student data comes from du_student_api. This file holds app constants.
const demoPhoto = 'assets/demo/rakshit.jpeg';
const appVersion = '3.0.5';

class MenuEntry {
  const MenuEntry(this.title, this.icon);
  final String title;
  final String icon;
}

const allMenu = [
  MenuEntry('Notifications', 'ic_gturesult.png'),
  MenuEntry('Attendance', 'ic_attendance.png'),
  MenuEntry('Fees', 'ic_feespaid.png'),
  MenuEntry('Time Table', 'ic_timetable.png'),
  MenuEntry('Academic Calendar', 'ic_calendar.png'),
  MenuEntry('LMS Dashboard', 'ic_library.png'),
  MenuEntry('Exam Schedule', 'dailywork.png'),
  MenuEntry('Circular', 'ic_circular.png'),
  MenuEntry('Mentoring', 'Mentoring.png'),
  MenuEntry('Certificate Request', 'certificate.png'),
  MenuEntry('Data Change Request', 'dataChange.png'),
  MenuEntry('Announcement', 'announcement.png'),
  MenuEntry('Transport', 'ic_bus_service.png'),
  MenuEntry('Bus Finder', 'bus-finder.png'),
  MenuEntry('Results', 'ic_gturesult.png'),
  MenuEntry('Feedback', 'ic_sms_sent.png'),
  MenuEntry('LMS Test Result', 'lms_test_mark.png'),
  MenuEntry('Punishment', 'Punishment.png'),
  MenuEntry('Hostel', 'hostel_icon.png'),
  MenuEntry('Grievance Registration', 'grievance.png'),
  MenuEntry('Term Registration', 'registration.png'),
];

const otherGrid = [
  MenuEntry('Announcement', 'announcement.png'),
  MenuEntry('Transport', 'ic_bus_service.png'),
  MenuEntry('Bus Finder', 'bus-finder.png'),
  MenuEntry('Results', 'ic_gturesult.png'),
  MenuEntry('Feedback', 'ic_sms_sent.png'),
  MenuEntry('LMS Test Result', 'lms_test_mark.png'),
  MenuEntry('Punishment', 'Punishment.png'),
  MenuEntry('Hostel', 'hostel_icon.png'),
  MenuEntry('Grievance Registration', 'grievance.png'),
  MenuEntry('Term Registration', 'registration.png'),
];

// ------------------------------------------------- Not served by the API
/// Subject codes on the dashboard strip, in display order.
const dashboardLmsCodes = ['2301HS503', '2301CS402', '2301CS501', '2301CS632'];
