// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

library DateTimeConvert {
    uint256 internal constant SECONDS_PER_DAY   = 24 * 60 * 60;
    uint256 internal constant SECONDS_PER_HOUR  = 60 * 60;
    uint256 internal constant SECONDS_PER_MINUTE= 60;
    uint256 internal constant EPOCH_ADJ_DAY     = 719468;   // days from 0000-03-01 to 1970-01-01
    uint256 internal constant DAYS_PER_400Y     = 146097;   // 365*400 + 97 (leap days)

    function timestampToDateTime(uint256 ts) internal pure returns (uint256 year, uint256 month, uint256 day, uint256 hour, uint256 minute, uint256 second) {
        unchecked {
            // ---- time-of-day ----
            uint256 sod = ts % SECONDS_PER_DAY;
            hour   = sod / SECONDS_PER_HOUR;
            minute = (sod % SECONDS_PER_HOUR) / SECONDS_PER_MINUTE;
            second = sod % SECONDS_PER_MINUTE;

            // ---- date ----
            uint256 daysSinceEpoch = ts / SECONDS_PER_DAY;

            // Convert days since 1970-01-01 to days since 0000-03-01
            uint256 z = daysSinceEpoch + EPOCH_ADJ_DAY;

            // Break into 400-year eras to avoid loops
            uint256 era = z / DAYS_PER_400Y;
            uint256 doe = z - era * DAYS_PER_400Y; // [0, 146096]

            // year-of-era (0..399)
            uint256 yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365;

            year = yoe + era * 400;

            // day-of-year (0..365)
            uint256 doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
            // month prime (0..11) from March=0 to Feb=11
            uint256 mp = (5 * doy + 2) / 153;

            day = doy - (153 * mp + 2) / 5 + 1;
            // March..December -> 3..12, January/February -> 1..2
            month = (mp < 10) ? (mp + 3) : (mp - 9);
            year += (month <= 2) ? 1 : 0; // Jan/Feb belong to next year in this mapping
        }
    }

    function timestampToDateTime() internal view returns (uint256 year, uint256 month, uint256 day, uint256 hour, uint256 minute, uint256 second) {
        uint256 ts = block.timestamp;

        unchecked {
            // ---- time-of-day ----
            uint256 sod = ts % SECONDS_PER_DAY;
            hour   = sod / SECONDS_PER_HOUR;
            minute = (sod % SECONDS_PER_HOUR) / SECONDS_PER_MINUTE;
            second = sod % SECONDS_PER_MINUTE;

            // ---- date ----
            uint256 daysSinceEpoch = ts / SECONDS_PER_DAY;

            // Convert days since 1970-01-01 to days since 0000-03-01
            uint256 z = daysSinceEpoch + EPOCH_ADJ_DAY;

            // Break into 400-year eras to avoid loops
            uint256 era = z / DAYS_PER_400Y;
            uint256 doe = z - era * DAYS_PER_400Y; // [0, 146096]

            // year-of-era (0..399)
            uint256 yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365;

            year = yoe + era * 400;

            // day-of-year (0..365)
            uint256 doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
            // month prime (0..11) from March=0 to Feb=11
            uint256 mp = (5 * doy + 2) / 153;

            day = doy - (153 * mp + 2) / 5 + 1;
            // March..December -> 3..12, January/February -> 1..2
            month = (mp < 10) ? (mp + 3) : (mp - 9);
            year += (month <= 2) ? 1 : 0; // Jan/Feb belong to next year in this mapping
        }
    }

    function getMonth(uint256 ts) internal pure returns (uint256 month) {
        
    }

    function getDay(uint256 ts) internal pure returns (uint256 day) {
        
    }

    function getHour(uint256 ts) internal pure returns (uint256 hour) {
        
    }

    function getMinute(uint256 ts) internal pure returns (uint256 minute) {
        
    }

    function getSecond(uint256 ts) internal pure returns (uint256 second) {
        
    }
}

contract DateTime {
    constructor() {
        
    }

    function timestampToDateTime(uint256 ts) external pure returns (uint256 year, uint256 month, uint256 day, uint256 hour, uint256 minute, uint256 second) {
        return DateTimeConvert.timestampToDateTime(ts);
    }

    function currentToDateTime() external view returns (uint256 year, uint256 month, uint256 day, uint256 hour, uint256 minute, uint256 second) {
        return DateTimeConvert.timestampToDateTime();
    }
}