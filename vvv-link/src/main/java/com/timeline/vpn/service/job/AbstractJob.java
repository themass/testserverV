package com.timeline.vpn.service.job;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public abstract class AbstractJob {
    protected static final Logger LOGGER = LoggerFactory.getLogger(AbstractJob.class);

    /**
     * The entrance function of the job.
     */
    public final void execute() {

        try {
            executeInternal();
        } catch (Exception e) {
            LOGGER.error(e.toString(), e);
        }
    }

    /**
     * The internal function which focus on the business logic.
     *
     * @throws Exception d
     */
    public abstract void executeInternal() throws Exception;
}
