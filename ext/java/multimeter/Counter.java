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

@JRubyClass(name="Multimeter::Counter")
public class Counter extends RubyObject {
  public static void setup(Ruby runtime) {
    RubyModule multimeterModule = runtime.defineModule("Multimeter");
    RubyClass cls = runtime.defineClassUnder("Counter", runtime.getObject(), ObjectAllocator.NOT_ALLOCATABLE_ALLOCATOR, multimeterModule);
    cls.defineAnnotatedMethods(Counter.class);
  }

  private com.codahale.metrics.Counter counter;

  public Counter(Ruby runtime, com.codahale.metrics.Counter counter) {
    super(runtime, runtime.getModule("Multimeter").getClass("Counter"));
    this.counter = counter;
  }

  @JRubyMethod
  public IRubyObject count(ThreadContext ctx) {
    return ctx.runtime.newFixnum(counter.getCount());
  }

  @JRubyMethod
  public IRubyObject inc(ThreadContext ctx) {
    counter.inc();
    return ctx.runtime.getNil();
  }

  @JRubyMethod
  public IRubyObject inc(ThreadContext ctx, IRubyObject amount) {
    counter.inc(amount.convertToInteger().getLongValue());
    return ctx.runtime.getNil();
  }

  @JRubyMethod
  public IRubyObject dec(ThreadContext ctx) {
    counter.dec();
    return ctx.runtime.getNil();
  }

  @JRubyMethod
  public IRubyObject dec(ThreadContext ctx, IRubyObject amount) {
    counter.dec(amount.convertToInteger().getLongValue());
    return ctx.runtime.getNil();
  }
}
