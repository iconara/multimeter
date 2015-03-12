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

@JRubyClass(name="Multimeter::Snapshot")
public class Snapshot extends RubyObject {
  public static void setup(Ruby runtime) {
    RubyModule multimeterModule = runtime.defineModule("Multimeter");
    RubyClass cls = runtime.defineClassUnder("Snapshot", runtime.getObject(), ObjectAllocator.NOT_ALLOCATABLE_ALLOCATOR, multimeterModule);
    cls.defineAnnotatedMethods(Snapshot.class);
  }

  private com.codahale.metrics.Snapshot snapshot;

  public Snapshot(Ruby runtime, com.codahale.metrics.Snapshot snapshot) {
    super(runtime, runtime.getModule("Multimeter").getClass("Snapshot"));
    this.snapshot = snapshot;
  }

  @JRubyMethod
  public IRubyObject size(ThreadContext ctx) {
    return ctx.runtime.newFixnum(snapshot.size());
  }

  @JRubyMethod
  public IRubyObject max(ThreadContext ctx) {
    return ctx.runtime.newFixnum(snapshot.getMax());
  }

  @JRubyMethod
  public IRubyObject min(ThreadContext ctx) {
    return ctx.runtime.newFixnum(snapshot.getMin());
  }

  @JRubyMethod
  public IRubyObject mean(ThreadContext ctx) {
    return ctx.runtime.newFloat(snapshot.getMean());
  }

  @JRubyMethod
  public IRubyObject median(ThreadContext ctx) {
    return ctx.runtime.newFloat(snapshot.getMedian());
  }

  @JRubyMethod(required=1)
  public IRubyObject value(ThreadContext ctx, IRubyObject percentile) {
    return ctx.runtime.newFloat(snapshot.getValue(percentile.convertToFloat().getDoubleValue()));
  }

  @JRubyMethod
  public IRubyObject values(ThreadContext ctx) {
    long[] values = snapshot.getValues();
    IRubyObject[] fixnums = new IRubyObject[values.length];
    for (int i = 0; i < values.length; i++) {
      fixnums[i] = ctx.runtime.newFixnum(values[i]);
    }
    return ctx.runtime.newArray(fixnums);
  }

  @JRubyMethod(name="std_dev")
  public IRubyObject stdDev(ThreadContext ctx) {
    return ctx.runtime.newFloat(snapshot.getStdDev());
  }

  @JRubyMethod(name="p75")
  public IRubyObject percentile75(ThreadContext ctx) {
    return ctx.runtime.newFloat(snapshot.get75thPercentile());
  }

  @JRubyMethod(name="p95")
  public IRubyObject percentile95(ThreadContext ctx) {
    return ctx.runtime.newFloat(snapshot.get95thPercentile());
  }

  @JRubyMethod(name="p98")
  public IRubyObject percentile98(ThreadContext ctx) {
    return ctx.runtime.newFloat(snapshot.get98thPercentile());
  }

  @JRubyMethod(name="p99")
  public IRubyObject percentile99(ThreadContext ctx) {
    return ctx.runtime.newFloat(snapshot.get99thPercentile());
  }

  @JRubyMethod(name="p999")
  public IRubyObject percentile999(ThreadContext ctx) {
    return ctx.runtime.newFloat(snapshot.get999thPercentile());
  }
}
