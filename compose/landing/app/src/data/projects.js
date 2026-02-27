const projects = [
  {
    name: "Interview",
    description:
      "AI-powered interview platform that maps your professional experience through conversation. Includes a promo landing page, backend API with LangGraph-driven interview workflows, and an MCP server for tool integration.",
    tech: ["Python", "FastAPI", "LangGraph", "SQLite", "Docker", "Traefik"],
    links: [
      { label: "Promo", url: "https://promo.interview.syncapp.tech" },
      { label: "API", url: "https://api.interview.syncapp.tech" },
      { label: "MCP", url: "https://mcp.interview.syncapp.tech" },
    ],
  },
  {
    name: "Price Alert Bot",
    description:
      "Telegram bot for cryptocurrency price alerts. Monitors prices via the CoinMarketCap API and sends notifications when user-defined thresholds are triggered.",
    tech: ["Go", "PostgreSQL", "PgBouncer", "Docker", "Telegram API"],
    links: [],
  },
];

export default projects;
