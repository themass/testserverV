package com.timeline.vpn.common.aspect;

import com.timeline.vpn.common.annotation.MethodTimed;
import io.micrometer.core.annotation.Incubating;
import io.micrometer.core.instrument.*;
import io.micrometer.core.lang.NonNullApi;
import lombok.extern.slf4j.Slf4j;
import org.aspectj.lang.ProceedingJoinPoint;
import org.aspectj.lang.Signature;
import org.aspectj.lang.annotation.Around;
import org.aspectj.lang.annotation.Aspect;
import org.aspectj.lang.annotation.Pointcut;
import org.aspectj.lang.reflect.MethodSignature;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.lang.reflect.Method;
import java.util.Optional;
import java.util.concurrent.CompletionStage;
import java.util.function.Function;

/**
 * 由@Timed改造而来
 */
@Aspect
@Component
@NonNullApi
@Incubating(since = "1.0.0")
@Slf4j
public class MethodTimedAspect {
    public static final String DEFAULT_METRIC_NAME = "method.timed";
    public static final String DEFAULT_EXCEPTION_TAG_VALUE = "none";
    @Value("${log.cost:true}")
    private boolean needCost;
    /**
     * Tag key for an exception.
     *
     * @since 1.1.0
     */
    public static final String EXCEPTION_TAG = "exception";

    private final MeterRegistry registry;
    private final Function<ProceedingJoinPoint, Iterable<Tag>> tagsBasedOnJoinPoint;

    /**
     * Create a {@code TimedAspect} instance with {@link Metrics#globalRegistry}.
     *
     * @since 1.2.0
     */
    public MethodTimedAspect() {
        this(Metrics.globalRegistry);
    }

    public MethodTimedAspect(MeterRegistry registry) {
        this(registry, pjp ->
                Tags.of("class", pjp.getStaticPart().getSignature().getDeclaringType().getSimpleName(),
                        "method", pjp.getStaticPart().getSignature().getName())
        );
    }

    public MethodTimedAspect(MeterRegistry registry, Function<ProceedingJoinPoint, Iterable<Tag>> tagsBasedOnJoinPoint) {
        this.registry = registry;
        this.tagsBasedOnJoinPoint = tagsBasedOnJoinPoint;
    }

    @Pointcut("@within(com.timeline.vpn.common.annotation.MethodTimed)")
    private void typeMonitor() {
    }

    @Pointcut("@annotation(com.timeline.vpn.common.annotation.MethodTimed)")
    private void methodMonitor() {
    }

    @Around("typeMonitor() || methodMonitor()")
    public Object timedMethod(ProceedingJoinPoint pjp) throws Throwable {
        Method method = ((MethodSignature) pjp.getSignature()).getMethod();
        MethodTimed timed = method.getAnnotation(MethodTimed.class);
        if (timed == null) {
            method = pjp.getTarget().getClass().getMethod(method.getName(), method.getParameterTypes());
            timed = method.getAnnotation(MethodTimed.class);
            timed = (timed == null) ? pjp.getTarget().getClass().getAnnotation(MethodTimed.class) : timed;
        }

        final String metricName = timed.value().isEmpty() ? DEFAULT_METRIC_NAME : timed.value();
        final boolean stopWhenCompleted = CompletionStage.class.isAssignableFrom(method.getReturnType());

        if (!timed.longTask()) {
            return processWithTimer(pjp, timed, metricName, stopWhenCompleted);
        } else {
            return processWithLongTaskTimer(pjp, timed, metricName, stopWhenCompleted);
        }
    }

    private Object processWithTimer(ProceedingJoinPoint pjp, MethodTimed timed, String metricName, boolean stopWhenCompleted) throws Throwable {

        Timer.Sample sample = Timer.start(registry);

        if (stopWhenCompleted) {
            try {
                return ((CompletionStage<?>) pjp.proceed()).whenComplete((result, throwable) ->
                        record(pjp, timed, metricName, sample, getExceptionTag(throwable)));
            } catch (Exception ex) {
                record(pjp, timed, metricName, sample, ex.getClass().getSimpleName());
                throw ex;
            }
        }

        String exceptionClass = DEFAULT_EXCEPTION_TAG_VALUE;
        String method = "";
        long times = System.currentTimeMillis();
        try {
            Signature signature = pjp.getSignature();
            method = signature.getDeclaringType().getSimpleName() + "." + signature.getName();
            return pjp.proceed();
        } catch (Exception ex) {
            exceptionClass = ex.getClass().getSimpleName();
            throw ex;
        } finally {
            record(pjp, timed, metricName, sample, exceptionClass);
            long cost = System.currentTimeMillis() - times;
            if (needCost && cost > 20) {
                log.info("Method耗时, name={}, cost={}", method, System.currentTimeMillis() - times);
            }
        }
    }

    private void record(ProceedingJoinPoint pjp, MethodTimed timed, String metricName, Timer.Sample sample, String exceptionClass) {
        try {
            sample.stop(Timer.builder(metricName)
                    .description(timed.description().isEmpty() ? null : timed.description())
                    .tags(timed.extraTags())
                    .tags(EXCEPTION_TAG, exceptionClass)
                    .tags(tagsBasedOnJoinPoint.apply(pjp))
                    .publishPercentileHistogram(timed.histogram())
                    .publishPercentiles(timed.percentiles().length == 0 ? null : timed.percentiles())
                    .register(registry));
        } catch (Exception e) {
            // ignoring on purpose
        }
    }

    private String getExceptionTag(Throwable throwable) {

        if (throwable == null) {
            return DEFAULT_EXCEPTION_TAG_VALUE;
        }

        if (throwable.getCause() == null) {
            return throwable.getClass().getSimpleName();
        }

        return throwable.getCause().getClass().getSimpleName();
    }

    private Object processWithLongTaskTimer(ProceedingJoinPoint pjp, MethodTimed timed, String metricName, boolean stopWhenCompleted) throws Throwable {

        Optional<LongTaskTimer.Sample> sample = buildLongTaskTimer(pjp, timed, metricName).map(LongTaskTimer::start);

        if (stopWhenCompleted) {
            try {
                return ((CompletionStage<?>) pjp.proceed()).whenComplete((result, throwable) -> sample.ifPresent(this::stopTimer));
            } catch (Exception ex) {
                sample.ifPresent(this::stopTimer);
                throw ex;
            }
        }

        try {
            return pjp.proceed();
        } finally {
            sample.ifPresent(this::stopTimer);
        }
    }

    private void stopTimer(LongTaskTimer.Sample sample) {
        try {
            sample.stop();
        } catch (Exception e) {
            // ignoring on purpose
        }
    }

    /**
     * Secure long task timer creation - it should not disrupt the application flow in case of exception
     */
    private Optional<LongTaskTimer> buildLongTaskTimer(ProceedingJoinPoint pjp, MethodTimed timed, String metricName) {
        try {
            return Optional.of(LongTaskTimer.builder(metricName)
                    .description(timed.description().isEmpty() ? null : timed.description())
                    .tags(timed.extraTags())
                    .tags(tagsBasedOnJoinPoint.apply(pjp))
                    .register(registry));
        } catch (Exception e) {
            return Optional.empty();
        }
    }
}
