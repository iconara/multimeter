package multimeter;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyModule;
import org.jruby.RubyObject;
import org.jruby.RubyHash;
import org.jruby.RubyArray;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.Block;
import org.jruby.runtime.ObjectAllocator;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;

import static org.jruby.runtime.Visibility.PRIVATE;

@JRubyClass(name="Multimeter::Meter")
public class Meter extends RubyObject {
  public static void setup(Ruby runtime) {
    RubyModule multimeterModule = runtime.defineModule("Multimeter");
    RubyClass cls = runtime.defineClassUnder("Meter", runtime.getObject(), ObjectAllocator.NOT_ALLOCATABLE_ALLOCATOR, multimeterModule);
    cls.defineAnnotatedMethods(Meter.class);
  }

  private com.codahale.metrics.Meter meter;

  public Meter(Ruby runtime, com.codahale.metrics.Meter meter) {
    super(runtime, runtime.getModule("Multimeter").getClass("Meter"));
    this.meter = meter;
  }

  @JRubyMethod
  public IRubyObject count(ThreadContext ctx) {
    return ctx.runtime.newFixnum(meter.getCount());
  }

  @JRubyMethod
  public IRubyObject mark(ThreadContext ctx) {
    meter.mark();
    return ctx.runtime.getNil();
  }

  @JRubyMethod
  public IRubyObject mark(ThreadContext ctx, IRubyObject amount) {
    meter.mark(amount.convertToInteger().getLongValue());
    return ctx.runtime.getNil();
  }

  @JRubyMethod(name="mean_rate")
  public IRubyObject meanRate(ThreadContext ctx) {
    return ctx.runtime.newFloat(meter.getMeanRate());
  }

  @JRubyMethod(name="one_minute_rate")
  public IRubyObject oneMinuteRate(ThreadContext ctx) {
    return ctx.runtime.newFloat(meter.getOneMinuteRate());
  }

  @JRubyMethod(name="five_minute_rate")
  public IRubyObject fiveMinuteRate(ThreadContext ctx) {
    return ctx.runtime.newFloat(meter.getFiveMinuteRate());
  }

  @JRubyMethod(name="fifteen_minute_rate")
  public IRubyObject fifteenMinuteRate(ThreadContext ctx) {
    return ctx.runtime.newFloat(meter.getFifteenMinuteRate());
  }
}
