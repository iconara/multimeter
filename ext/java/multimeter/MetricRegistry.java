package multimeter;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyModule;
import org.jruby.RubyObject;
import org.jruby.RubyHash;
import org.jruby.RubyArray;
import org.jruby.RubyProc;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.Block;
import org.jruby.runtime.ObjectAllocator;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.javasupport.JavaUtil;

import static org.jruby.runtime.Visibility.PRIVATE;

@JRubyClass(name="Multimeter::MetricRegistry")
public class MetricRegistry extends RubyObject {
  public static void setup(Ruby runtime) {
    RubyModule multimeterModule = runtime.defineModule("Multimeter");
    RubyClass cls = runtime.defineClassUnder("MetricRegistry", runtime.getObject(), ALLOCATOR, multimeterModule);
    cls.defineAnnotatedMethods(MetricRegistry.class);
  }

  private static final ObjectAllocator ALLOCATOR = new ObjectAllocator() {
    @Override
    public IRubyObject allocate(Ruby runtime, RubyClass klass) {
      return new MetricRegistry(runtime, klass);
    }
  };

  private com.codahale.metrics.MetricRegistry registry;
  private RubyHash metrics;

  public MetricRegistry(Ruby runtime, RubyClass type) {
    super(runtime, type);
    this.registry = new com.codahale.metrics.MetricRegistry();
    this.metrics = RubyHash.newHash(runtime);
  }

  @JRubyMethod(name="to_java")
  public IRubyObject toJava(ThreadContext ctx) {
    return JavaUtil.convertJavaToUsableRubyObject(ctx.runtime, registry);
  }

  @JRubyMethod
  public IRubyObject metrics(ThreadContext ctx) {
    return metrics;
  }

  @JRubyMethod
  public IRubyObject counter(ThreadContext ctx, IRubyObject arg) {
    String name = arg.asJavaString();
    Counter wrapper = new Counter(ctx.runtime, registry.counter(name));
    metrics.fastASet(arg, wrapper);
    return wrapper;
  }

  @JRubyMethod
  public IRubyObject meter(ThreadContext ctx, IRubyObject arg) {
    String name = arg.asJavaString();
    Meter wrapper = new Meter(ctx.runtime, registry.meter(name));
    metrics.fastASet(arg, wrapper);
    return wrapper;
  }

  @JRubyMethod
  public IRubyObject timer(ThreadContext ctx, IRubyObject arg) {
    String name = arg.asJavaString();
    Timer wrapper = new Timer(ctx.runtime, registry.timer(name));
    metrics.fastASet(arg, wrapper);
    return wrapper;
  }

  @JRubyMethod
  public IRubyObject histogram(ThreadContext ctx, IRubyObject arg) {
    String name = arg.asJavaString();
    Histogram wrapper = new Histogram(ctx.runtime, registry.histogram(name));
    metrics.fastASet(arg, wrapper);
    return wrapper;
  }

  @JRubyMethod
  public IRubyObject gauge(final ThreadContext ctx, IRubyObject arg, final Block block) {
    String name = arg.asJavaString();
    final RubyProc callback = ctx.runtime.newProc(Block.Type.PROC, block);
    Gauge wrapper = new Gauge(ctx.runtime, registry.register(name, new com.codahale.metrics.Gauge<IRubyObject>() {
      @Override
      public IRubyObject getValue() {
        return callback.call19(ctx, IRubyObject.NULL_ARRAY, Block.NULL_BLOCK);
      }
    }));
    metrics.fastASet(arg, wrapper);
    return wrapper;
  }
}
