const projects = [
  {
    name: "Interview",
    description:
      "AI-powered interview platform that maps professional experience through multi-turn conversation. Uses LangGraph agent orchestration with sub-graphs, vector database for context retrieval, and LLM evaluation pipeline with automated regression testing.",
    tech: ["Python", "FastAPI", "LangGraph", "RAG", "SQLite", "Docker"],
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
    name: "Tools Platform",
    description:
      "A suite of lightweight microservices — URL shortener, HTML page hosting, and a contact form API — unified through an MCP (Model Context Protocol) aggregator server for LLM tool integration.",
    tech: ["Rust", "Axum", "Redis", "PostgreSQL", "MCP", "Docker"],
    links: [
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
        github: "https://github.com/ku113p/short-links",
      },
      {
        name: "Landing Pages",
        description: "HTML page hosting microservice.",
        github: "https://github.com/ku113p/landing-pages",
      },
      {
        name: "Message",
        description: "Contact form API microservice.",
        github: "https://github.com/ku113p/message",
      },
    ],
  },
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
  {
    name: "Crypto Assets",
    description:
      "DeFi portfolio tracker for managing token balances, protocol allocations, and analytics. Lightweight HTMX interface with real-time server-side rendering.",
    tech: ["Rust", "Axum", "HTMX", "Docker"],
    links: [
      { label: "Open App", url: "https://assets.crypto.syncapp.tech" },
      {
        label: "GitHub",
        url: "https://github.com/ku113p/crypto-assets",
        icon: "github",
      },
    ],
  },
];

export default projects;
