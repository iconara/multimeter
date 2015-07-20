import java.io.IOException;

import org.jruby.Ruby;
import org.jruby.runtime.load.BasicLibraryService;

import multimeter.MetricRegistry;
import multimeter.Counter;
import multimeter.Meter;
import multimeter.Timer;
import multimeter.Histogram;
import multimeter.Snapshot;
import multimeter.Gauge;
import multimeter.JSONSerializer;

public class MultimeterMetricsService implements BasicLibraryService {
  public boolean basicLoad(final Ruby runtime) throws IOException {
    MetricRegistry.setup(runtime);
    Counter.setup(runtime);
    Meter.setup(runtime);
    Timer.setup(runtime);
    Histogram.setup(runtime);
    Snapshot.setup(runtime);
    Gauge.setup(runtime);
    JSONSerializer.setup(runtime);
    return true;
  }
}
