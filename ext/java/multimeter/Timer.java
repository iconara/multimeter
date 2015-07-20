package multimeter;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyModule;
import org.jruby.RubyObject;
import org.jruby.RubyHash;
import org.jruby.RubyArray;
import org.jruby.RubyString;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.Block;
import org.jruby.runtime.ObjectAllocator;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.javasupport.JavaUtil;

import static org.jruby.runtime.Visibility.PRIVATE;

import java.util.concurrent.TimeUnit;
import java.util.concurrent.Callable;

@JRubyClass(name="Multimeter::Timer")
public class Timer extends RubyObject {
  public static void setup(Ruby runtime) {
    RubyModule multimeterModule = runtime.defineModule("Multimeter");
    RubyClass cls = runtime.defineClassUnder("Timer", runtime.getObject(), ObjectAllocator.NOT_ALLOCATABLE_ALLOCATOR, multimeterModule);
    cls.defineAnnotatedMethods(Timer.class);
    cls = runtime.defineClassUnder("TimerContext", runtime.getObject(), ObjectAllocator.NOT_ALLOCATABLE_ALLOCATOR, cls);
    cls.defineAnnotatedMethods(TimerContext.class);
  }

  private com.codahale.metrics.Timer timer;

  public Timer(Ruby runtime, com.codahale.metrics.Timer timer) {
    super(runtime, runtime.getModule("Multimeter").getClass("Timer"));
    this.timer = timer;
  }

  @JRubyMethod(name="to_java")
  public IRubyObject toJava(ThreadContext ctx) {
    return JavaUtil.convertJavaToUsableRubyObject(ctx.runtime, timer);
  }

  @JRubyMethod(name="to_json")
  public RubyString toJson(ThreadContext ctx) {
    return JSONSerializer.getInstance().serialize(ctx, timer);
  }

  @JRubyMethod
  public IRubyObject count(ThreadContext ctx) {
    return ctx.runtime.newFixnum(timer.getCount());
  }

  @JRubyMethod(required=1)
  public IRubyObject update(ThreadContext ctx, IRubyObject d) {
    double duration = d.convertToFloat().getDoubleValue() * 1000000;
    TimeUnit unit = TimeUnit.MICROSECONDS;
    timer.update((long) duration, unit);
    return ctx.runtime.getNil();
  }

  @JRubyMethod(required=2)
  public IRubyObject update(ThreadContext ctx, IRubyObject d, IRubyObject u) {
    try {
      long duration = d.convertToInteger().getLongValue();
      TimeUnit unit = TimeUnit.valueOf(u.asJavaString().toUpperCase());
      timer.update(duration, unit);
      return ctx.runtime.getNil();
    } catch (IllegalArgumentException iae) {
      throw ctx.runtime.newArgumentError(String.format("Time unit \"%s\" not supported", u.asJavaString()));
    }
  }

  @JRubyMethod
  public IRubyObject time(final ThreadContext ctx, final Block block) throws Exception {
    if (block.isGiven()) {
      return timer.time(new Callable<IRubyObject>() {
        @Override
        public IRubyObject call() {
          return block.yieldSpecific(ctx);
        }
      });
    } else {
      return new TimerContext(ctx.runtime, timer.time());
    }
  }

  @JRubyMethod(name="mean_rate")
  public IRubyObject meanRate(ThreadContext ctx) {
    return ctx.runtime.newFloat(timer.getMeanRate());
  }

  @JRubyMethod(name="one_minute_rate")
  public IRubyObject oneMinuteRate(ThreadContext ctx) {
    return ctx.runtime.newFloat(timer.getOneMinuteRate());
  }

  @JRubyMethod(name="five_minute_rate")
  public IRubyObject fiveMinuteRate(ThreadContext ctx) {
    return ctx.runtime.newFloat(timer.getFiveMinuteRate());
  }

  @JRubyMethod(name="fifteen_minute_rate")
  public IRubyObject fifteenMinuteRate(ThreadContext ctx) {
    return ctx.runtime.newFloat(timer.getFifteenMinuteRate());
  }

  @JRubyMethod
  public IRubyObject snapshot(ThreadContext ctx) {
    return new Snapshot(ctx.runtime, timer.getSnapshot());
  }

  @JRubyClass(name="Multimeter::Timer::TimerContext")
  public static class TimerContext extends RubyObject {
    private com.codahale.metrics.Timer.Context context;

    public TimerContext(Ruby runtime, com.codahale.metrics.Timer.Context context) {
      super(runtime, runtime.getModule("Multimeter").getClass("Timer").getClass("TimerContext"));
      this.context = context;
    }

    @JRubyMethod
    public IRubyObject stop(ThreadContext ctx) {
      return ctx.runtime.newFixnum(context.stop());
    }
  }
}
