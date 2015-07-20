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

@JRubyClass(name="Multimeter::Histogram")
public class Histogram extends RubyObject {
  public static void setup(Ruby runtime) {
    RubyModule multimeterModule = runtime.defineModule("Multimeter");
    RubyClass cls = runtime.defineClassUnder("Histogram", runtime.getObject(), ObjectAllocator.NOT_ALLOCATABLE_ALLOCATOR, multimeterModule);
    cls.defineAnnotatedMethods(Histogram.class);
  }

  private com.codahale.metrics.Histogram histogram;

  public Histogram(Ruby runtime, com.codahale.metrics.Histogram histogram) {
    super(runtime, runtime.getModule("Multimeter").getClass("Histogram"));
    this.histogram = histogram;
  }

  @JRubyMethod(name="to_java")
  public IRubyObject toJava(ThreadContext ctx) {
    return JavaUtil.convertJavaToUsableRubyObject(ctx.runtime, histogram);
  }

  @JRubyMethod(name="to_json")
  public RubyString toJson(ThreadContext ctx) {
    return JSONSerializer.getInstance().serialize(ctx, histogram);
  }

  @JRubyMethod
  public IRubyObject count(ThreadContext ctx) {
    return ctx.runtime.newFixnum(histogram.getCount());
  }

  @JRubyMethod(required=1)
  public IRubyObject update(ThreadContext ctx, IRubyObject value) {
    histogram.update(value.convertToInteger().getLongValue());
    return ctx.runtime.getNil();
  }

  @JRubyMethod
  public IRubyObject snapshot(ThreadContext ctx) {
    return new Snapshot(ctx.runtime, histogram.getSnapshot());
  }
}
