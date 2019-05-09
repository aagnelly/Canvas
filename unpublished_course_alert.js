// ==UserScript==
// @name Unpublished courses
// @namespace Audra Agnelly
// @version 1
// @description Posts an alert on the Canvas dashboard listing teacher's unpublished courses
// @match https://hcpss.instructure.com/
// @grant none
// ==/UserScript==


//Term IDs for 18-19:
//FY = 108, EY = 107, S1 = 113, S2 = 114, E1 = 105, E2 = 106



var url = 'https://hcpss.instructure.com/api/v1/courses?state[]=unpublished';
    $.getJSON(url, function(data, status, jqXHR){
        var count = 0;

        var courseList = '';
            data.forEach(course => {
            if (course.enrollment_term_id=='108'||course.enrollment_term_id=='107' ){ //FY and EY terms
                courseList = courseList + ('    ' + course.name + '\n');
                count++;
            }
            else if (course.enrollment_term_id=='113'||course.enrollment_term_id=='105' ){ //S1 and E1 terms, comment out for semester 2
                courseList = courseList + ('    ' + course.name + '\n');
                count++;
            }
            else if (course.enrollment_term_id=='114'||course.enrollment_term_id=='106' ){ //S2 and E2 terms, comment out for semester 1
                courseList = courseList + ('    ' + course.name + '\n');
                count++;
            }
        });
        if (count > 0) {
            alert(count + ' of your current Canvas courses have not been published yet. Unpublished courses cannot be seen by students or parents:\n\n' + courseList);
        };
    });
