/* The engine runs in a dedicated worker so analysis never blocks board input. */
(async () => {
  importScripts('../vendor/pikafish.js');
  const engine = await Pikafish({
    locateFile: file => new URL(`../vendor/${file}`, self.location.href).href,
  });
  engine.read_stdout = output => {
    for (const line of String(output).split(/\r?\n/)) {
      if (line.trim()) self.postMessage({ type: 'line', line: line.trim() });
    }
  };
  self.onmessage = ({ data }) => {
    if (data.type === 'command') engine.send_command(data.value);
  };
  self.postMessage({ type: 'ready' });
})().catch(error => {
  self.postMessage({ type: 'error', message: String(error?.message ?? error) });
});
