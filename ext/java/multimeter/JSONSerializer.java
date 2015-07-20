package multimeter;

import com.codahale.metrics.json.MetricsModule;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.concurrent.TimeUnit;
import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyException;
import org.jruby.exceptions.RaiseException;
import org.jruby.RubyModule;
import org.jruby.RubyString;
import org.jruby.anno.JRubyClass;
import org.jruby.runtime.ThreadContext;

public class JSONSerializer {
  private ObjectMapper mapper;
  private MetricsModule module;

  public static void setup(Ruby runtime) {
    RubyModule multimeterModule = runtime.defineModule("Multimeter");
    RubyClass standardError = runtime.getStandardError();
    multimeterModule.defineClassUnder("JSONError", standardError, standardError.getAllocator());
  }

  @JRubyClass(name="Multimeter::JSONError", parent="StandardError")
  public static class JSONError {}

  private static JSONSerializer instance;

  public static JSONSerializer getInstance() {
    if ( instance == null ) {
      instance = new JSONSerializer();
    }
    return instance;
  }

  private JSONSerializer() {
    this.mapper = new ObjectMapper();
    this.module = new MetricsModule(TimeUnit.SECONDS, TimeUnit.MILLISECONDS, false);
    mapper.registerModule(module);
  }

  public RubyString serialize(ThreadContext ctx, Object object) {
    ByteArrayOutputStream stream = new ByteArrayOutputStream();
    try {
      mapper.writeValue(stream, object);
      return RubyString.newString(ctx.runtime, stream.toByteArray());
    } catch (IOException e) {
      RubyClass jsonError = ctx.runtime.getModule("Multimeter").getClass("JSONError");
      throw new RaiseException(RubyException.newException(ctx.runtime, jsonError, e.toString()), false);
    }
  }
}