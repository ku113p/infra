const projects = [
  {
    name: "CryoPay",
    description:
      "Blockchain-based payment platform for creating and managing crypto invoices. Supports Optimism and Arbitrum networks with USDT, features Firebase auth, email and Telegram notifications, subscriptions, donations, webhooks, and an API for integration.",
    tech: ["Rust", "Axum", "React", "PostgreSQL", "Redis", "Solidity", "Docker"],
    links: [
      { label: "Open App", url: "https://pay.syncapp.tech" },
      {
        label: "GitHub",
        url: "https://github.com/digitalscyther/cryo-pay",
        icon: "github",
      },
    ],
  },
  {
    name: "Tools Platform",
    description:
      "A suite of lightweight developer-tool microservices — URL shortener, HTML page hosting, and a contact form API — unified through an MCP aggregator server for programmatic access.",
    tech: ["Rust", "Axum", "Redis", "PostgreSQL", "MCP", "Docker"],
    links: [
      { label: "MCP Server", url: "https://mcp.tools.syncapp.tech" },
      {
        label: "GitHub",
        url: "https://github.com/ku113p/tools-mcp",
        icon: "github",
      },
    ],
    subProjects: [
      {
        name: "Short Links",
        description: "URL shortener microservice.",
        links: [
          { label: "Live", url: "https://links.tools.syncapp.tech" },
          { label: "GitHub", url: "https://github.com/ku113p/short-links", icon: "github" },
        ],
      },
      {
        name: "Landing Pages",
        description: "HTML page hosting microservice.",
        links: [
          { label: "Live", url: "https://pages.tools.syncapp.tech" },
          { label: "GitHub", url: "https://github.com/ku113p/landing-pages", icon: "github" },
        ],
      },
      {
        name: "Message",
        description: "Contact form API microservice.",
        links: [
          { label: "Live", url: "https://msg.tools.syncapp.tech" },
          { label: "GitHub", url: "https://github.com/ku113p/message", icon: "github" },
        ],
      },
    ],
  },
  {
    name: "Interview",
    description:
      "AI-powered interview platform that maps your professional experience through conversation. Includes a promo landing page, backend API with LangGraph-driven interview workflows, and an MCP server for tool integration.",
    tech: ["Python", "FastAPI", "LangGraph", "SQLite", "Docker"],
    links: [
      { label: "Promo", url: "https://promo.interview.syncapp.tech" },
      {
        label: "GitHub",
        url: "https://github.com/ku113p/interview",
        icon: "github",
      },
    ],
  },
  {
    name: "Price Alert Bot",
    description:
      "Telegram bot for cryptocurrency price alerts. Monitors prices via the CoinMarketCap API and sends notifications when user-defined thresholds are triggered.",
    tech: ["Go", "PostgreSQL", "PgBouncer", "Docker", "Telegram API"],
    links: [
      {
        label: "Open in Telegram",
        url: "https://t.me/token_price_signal_bot",
        icon: "telegram",
      },
      {
        label: "GitHub",
        url: "https://github.com/ku113p/price-alert-bot",
        icon: "github",
      },
    ],
  },
];

export default projects;
