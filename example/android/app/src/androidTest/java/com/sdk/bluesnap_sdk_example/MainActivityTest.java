package com.sdk.bluesnap_sdk_example;

import androidx.test.rule.ActivityTestRule;
import dev.flutter.plugins.integration_test.FlutterTestRunner;
import org.junit.Rule;
import org.junit.runner.RunWith;

// Runs the Dart integration tests (integration_test/) as Android instrumentation
// tests, e.g. on Firebase Test Lab. See example/integration_test/README.md.
@RunWith(FlutterTestRunner.class)
public class MainActivityTest {
  @Rule
  public ActivityTestRule<MainActivity> rule = new ActivityTestRule<>(MainActivity.class, true, false);
}
