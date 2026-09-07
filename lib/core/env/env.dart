/// Compile-time config injected via `--dart-define-from-file=env/dev.json`
/// (or `env/prod.json`). No runtime config screen — see CLAUDE.md §Auth.
abstract final class Env {
  static const String baseUrl = String.fromEnvironment('BASE_URL');
  static const String apiKey = String.fromEnvironment('API_KEY');
}
