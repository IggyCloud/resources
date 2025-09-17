bash <<'EOF'
echo "🔧  Installing Claude MCP servers (latest versions)…"

# Sequential Thinking — Claude's chain‑of‑thought engine
claude mcp add sequential-thinking -s user \
  -- npx -y @modelcontextprotocol/server-sequential-thinking || true

# Filesystem — give Claude access to local folders
claude mcp add filesystem -s user \
  -- npx -y @modelcontextprotocol/server-filesystem \
     ~/Documents ~/Desktop ~/Downloads ~/Projects || true

# Playwright — modern multi‑browser automation
claude mcp add playwright -s user \
  -- npx -y @playwright/mcp-server || true

# Puppeteer — Chrome‑only (deprecated but still works)
claude mcp add puppeteer -s user \
  -- npx -y @modelcontextprotocol/server-puppeteer || true

# Fetch — simple HTTP GET/POST
claude mcp add fetch -s user \
  -- npx -y @kazuph/mcp-fetch || true

# Browser‑Tools — DevTools logs, screenshots, etc.
claude mcp add browser-tools -s user \
  -- npx -y @agentdeskai/browser-tools-mcp || true

echo "--------------------------------------------------"
echo "✅  MCP registration finished."
echo ""
echo "🔴  To enable Browser‑Tools, run this in a *second* terminal and leave it open:"
echo "    npx -y @agentdeskai/browser-tools-server"
echo "--------------------------------------------------"
claude mcp list
EOF