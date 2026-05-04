const assert = require("assert");
const fs = require("fs");
const path = require("path");

describe("install-lite.sh regression guards", () => {
  const scriptPath = path.join(__dirname, "..", "install-lite.sh");
  const scriptContent = fs.readFileSync(scriptPath, "utf8");

  it("requires interactive TTY input to avoid non-responsive runs", () => {
    assert(
      /if \[ ! -t 0 \] \|\| \[ ! -t 1 \]/.test(scriptContent),
      "install-lite.sh should guard against non-interactive stdin/stdout",
    );
  });

  it("has stale-lock recovery and active-process detection for reruns", () => {
    assert(
      /LOCK_FILE="\$CONFIG_DIR\/\.install-lite\.lock"/.test(scriptContent),
      "install-lite.sh should define a lock file",
    );
    assert(
      /kill -0 "\$EXISTING_PID"/.test(scriptContent),
      "install-lite.sh should detect active installer process by PID",
    );
  });

  it("restores terminal state and clears runtime lock on interrupt/exit", () => {
    assert(
      /cleanup_install_runtime\(\)/.test(scriptContent),
      "install-lite.sh should define cleanup_install_runtime",
    );
    assert(
      /trap cleanup_install_runtime EXIT/.test(scriptContent),
      "install-lite.sh should cleanup runtime state on EXIT",
    );
    assert(
      /trap handle_install_interrupt INT TERM/.test(scriptContent),
      "install-lite.sh should handle INT/TERM and restore terminal state",
    );
  });
});
