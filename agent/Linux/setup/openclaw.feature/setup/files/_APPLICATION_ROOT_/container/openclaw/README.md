Ubuntu 24.04 container with seven AI coding providers behind a single toggle.
| Flag       | Tool                    | Key env var                                   |
| ---------- | ----------------------- | --------------------------------------------- |
| `claude`   | Claude Code (Anthropic) | `ANTHROPIC_API_KEY`                           |
| `codex`    | OpenAI / Codex          | `OPENAI_API_KEY`                              |
| `copilot`  | GitHub Copilot CLI      | `GITHUB_TOKEN`                                |
| `gemini`   | Gemini CLI (Google)     | `GEMINI_API_KEY`                              |
| `kiro`     | Kiro (AWS Bedrock)      | `AWS_ACCESS_KEY_ID` + `AWS_SECRET_ACCESS_KEY` |
| `qwen`     | Qwen / DashScope        | `DASHSCOPE_API_KEY`                           |
| `opencode` | OpenCode                | `OPENCODE_CONFIG` (optional JSON)             |
```bash
cp .env.example .env && $EDITOR .env
podman build -t openclaw:latest .
chmod +x oc.sh
./oc.sh claude
./oc.sh gemini
./oc.sh codex
podman-compose --profile claude   up
podman-compose --profile gemini   up
podman-compose --profile opencode up
```
Just bring one service down and another up – the named volume `openclaw-config`
persists credentials/config across all of them:
```bash
podman-compose --profile claude   down
podman-compose --profile copilot  up
```
Your local code is mapped into `/workspace` inside the container.
By default this is `./workspace` (created automatically).
Override by setting `HOST_WORKSPACE` in your `.env`:
```
HOST_WORKSPACE=/home/you/projects/my-app
```
```bash
./oc.sh claude --build
podman-compose --profile claude run --rm claude bash
```
- Podman ≥ 4.x + `podman-compose`
- Or Docker Engine + Docker Compose v2 (for local dev / fallback)
