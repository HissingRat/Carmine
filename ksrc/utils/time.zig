pub const UtcTime = struct {
    year: i32,
    month: u8,
    day: u8,
    hour: u8,
    minute: u8,
    second: u8,
};

const days_before_month_common = [_]u16{ 0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334 };

fn isLeap(year: i32) bool {
    return (@rem(year, 4) == 0 and @rem(year, 100) != 0) or (@rem(year, 400) == 0);
}

pub fn unixToUtc(timestamp: i64) UtcTime {
    const secs_per_day: i64 = 86400;
    const secs_per_hour: i64 = 3600;
    const secs_per_min: i64 = 60;

    const days_since_epoch = @divFloor(timestamp, secs_per_day);
    const day_seconds = @mod(timestamp, secs_per_day);

    const hour: u8 = @intCast(@divFloor(day_seconds, secs_per_hour));
    const rem_after_hour = @rem(day_seconds, secs_per_hour);
    const minute: u8 = @intCast(@divFloor(rem_after_hour, secs_per_min));
    const second: u8 = @intCast(@rem(rem_after_hour, secs_per_min));

    var year: i32 = 1970;
    var days_remaining = days_since_epoch;

    const days_per_400y: i64 = 146097;
    const cycles = @divFloor(days_remaining, days_per_400y);
    year += @intCast(cycles * 400);
    days_remaining -= cycles * days_per_400y;

    while (true) {
        const days_in_year: i64 = if (isLeap(year)) 366 else 365;
        if (days_remaining < days_in_year) break;
        days_remaining -= days_in_year;
        year += 1;
    }

    const day_of_year: u16 = @intCast(days_remaining + 1);
    const leap = isLeap(year);

    var month: u8 = 1;
    var day: u8 = 1;

    var m: u8 = 12;
    while (m >= 1) : (m -= 1) {
        var offset = days_before_month_common[m - 1];
        if (leap and m > 2) offset += 1;
        if (day_of_year > offset) {
            month = m;
            day = @intCast(day_of_year - offset);
            break;
        }
    }

    return UtcTime{
        .year = year,
        .month = month,
        .day = day,
        .hour = hour,
        .minute = minute,
        .second = second,
    };
}
