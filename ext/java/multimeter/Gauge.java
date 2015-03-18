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
import org.jruby.javasupport.JavaUtil;

import static org.jruby.runtime.Visibility.PRIVATE;

@JRubyClass(name="Multimeter::Gauge")
public class Gauge extends RubyObject {
  public static void setup(Ruby runtime) {
    RubyModule multimeterModule = runtime.defineModule("Multimeter");
    RubyClass cls = runtime.defineClassUnder("Gauge", runtime.getObject(), ObjectAllocator.NOT_ALLOCATABLE_ALLOCATOR, multimeterModule);
    cls.defineAnnotatedMethods(Gauge.class);
  }

  private com.codahale.metrics.Gauge<? extends Object> gauge;

  public Gauge(Ruby runtime, com.codahale.metrics.Gauge<? extends Object> gauge) {
    super(runtime, runtime.getModule("Multimeter").getClass("Gauge"));
    this.gauge = gauge;
  }

  @JRubyMethod
  public IRubyObject value(ThreadContext ctx) {
    Object value = gauge.getValue();
    if (value instanceof IRubyObject) {
      return (IRubyObject) value;
    } else {
      return JavaUtil.convertJavaToUsableRubyObject(ctx.runtime, value);
    }
  }
}
