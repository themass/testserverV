package com.timeline.poetry.domain;

/** Historical year numbers: BCE is negative; there is no year zero. */
public record TimeSpan(Integer startYear, Integer endYear, String precision) {
    public TimeSpan {
        if (!Vocabulary.isMember(Vocabulary.TIME_PRECISIONS, precision))
            throw new IllegalArgumentException("Invalid time precision");
        if ((startYear != null && startYear == 0) || (endYear != null && endYear == 0))
            throw new IllegalArgumentException("Historical dates have no year zero");
        if ("UNKNOWN".equals(precision)) {
            if (startYear != null || endYear != null) throw new IllegalArgumentException("Unknown dates must be null");
        } else {
            if (startYear == null || endYear == null || startYear > endYear)
                throw new IllegalArgumentException("A known date requires ordered bounds");
            if ("EXACT".equals(precision) && !startYear.equals(endYear))
                throw new IllegalArgumentException("An exact year requires equal bounds");
        }
    }
}
