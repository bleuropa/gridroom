# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Gridroom.Repo.insert!(%Gridroom.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Gridroom.Repo
alias Gridroom.Folders.Folder

# MDR-style folders with category-specific system prompts and completion messages

folders = [
  %{
    slug: "sports",
    name: "Sports",
    description: "Athletic competitions, scores, and player developments",
    icon: "trophy",
    sort_order: 0,
    system_prompt: """
    Search X for trending sports topics and return 7-9 DIVERSE conversation starters.

    CRITICAL: You MUST use the search tool to find REAL trending sports content. Do NOT make up topics.

    Focus on:
    - Major league updates (NFL, NBA, MLB, NHL, soccer leagues)
    - Player trades, injuries, comebacks
    - Championship races and playoff implications
    - Emerging athletes and breakout performances
    - Controversial calls and referee decisions
    - Sports culture and fan experiences

    AVOID: Fantasy sports advice, betting odds, generic game recaps.

    FORMAT each topic as:
    N. **Title**: Brief description of why it's interesting for discussion

    Return exactly 7-9 topics. Each should spark genuine conversation.
    """,
    completion_message: """
    Your dedication to athletic data refinement has brought balance to the numbers.

    The scores have been sorted. The standings now rest in harmony.

    Kier smiles upon your efforts, refiner.
    """
  },
  %{
    slug: "gossip",
    name: "Gossip",
    description: "Celebrity news, entertainment, and pop culture drama",
    icon: "sparkles",
    sort_order: 1,
    system_prompt: """
    Search X for trending celebrity and entertainment topics and return 7-9 DIVERSE conversation starters.

    CRITICAL: You MUST use the search tool to find REAL trending entertainment content. Do NOT make up topics.

    Focus on:
    - Celebrity relationships and breakups
    - Award show moments and fashion
    - Music releases and tour announcements
    - TV show drama (cast changes, plot reveals)
    - Influencer controversies
    - Viral celebrity moments

    AVOID: Unfounded rumors, invasive personal speculation, promotional content.

    FORMAT each topic as:
    N. **Title**: Brief description of why it's interesting for discussion

    Return exactly 7-9 topics. Each should spark genuine conversation.
    """,
    completion_message: """
    The whispers have been sorted. The frequencies now hum in unison.

    Your work brings harmony to the social patterns that others fear to examine.

    Rest well, refiner. The gossip thanks you for your service.
    """
  },
  %{
    slug: "tech",
    name: "Tech",
    description: "Technology trends, product launches, and industry news",
    icon: "cpu",
    sort_order: 2,
    system_prompt: """
    Search X for trending technology topics and return 7-9 DIVERSE conversation starters.

    CRITICAL: You MUST use the search tool to find REAL trending tech content. Do NOT make up topics.

    Focus on:
    - New product launches and reviews
    - AI developments (but not just hype)
    - Cybersecurity incidents and privacy concerns
    - Startup news and acquisitions
    - Open source developments
    - Tech policy and regulation
    - Developer culture and tools

    AVOID: Generic AI hype, crypto speculation, obvious marketing.

    FORMAT each topic as:
    N. **Title**: Brief description of why it's interesting for discussion

    Return exactly 7-9 topics. Diversity is required - don't cluster on AI.
    """,
    completion_message: """
    The digital frontiers bow to your precision.

    Code and silicon now rest in their proper configurations.

    Kier thanks you for taming the innovation chaos, refiner.
    """
  },
  %{
    slug: "politics",
    name: "Politics",
    description: "Political news, policy debates, and current affairs",
    icon: "landmark",
    sort_order: 3,
    system_prompt: """
    Search X for trending political topics and return 7-9 DIVERSE conversation starters.

    CRITICAL: You MUST use the search tool to find REAL trending political content. Do NOT make up topics.

    Focus on:
    - Policy debates and legislative developments
    - Election news and campaign updates
    - International relations and diplomacy
    - Government decisions and their impact
    - Political movements and activism
    - Bipartisan issues and common ground

    IMPORTANT: Present topics neutrally. Avoid partisan framing.
    AVOID: Inflammatory rhetoric, conspiracy theories, personal attacks.

    FORMAT each topic as:
    N. **Title**: Brief description of why it's interesting for discussion

    Return exactly 7-9 topics. Balance perspectives where applicable.
    """,
    completion_message: """
    The civic patterns are now clear. Democracy's data rests in order.

    Your service to the democratic process is noted and deeply appreciated.

    The board extends its gratitude, refiner.
    """
  },
  %{
    slug: "finance",
    name: "Finance",
    description: "Markets, economy, and business developments",
    icon: "chart",
    sort_order: 4,
    system_prompt: """
    Search X for trending finance and business topics and return 7-9 DIVERSE conversation starters.

    CRITICAL: You MUST use the search tool to find REAL trending finance content. Do NOT make up topics.

    Focus on:
    - Major market movements and their causes
    - Company earnings and business developments
    - Economic indicators and trends
    - Entrepreneurship and startup stories
    - Personal finance debates
    - Industry disruptions and innovations

    AVOID: Investment advice, crypto shilling, get-rich-quick content.

    FORMAT each topic as:
    N. **Title**: Brief description of why it's interesting for discussion

    Return exactly 7-9 topics. Each should spark genuine conversation.
    """,
    completion_message: """
    The ledgers balance. The markets find their equilibrium through your efforts.

    Numbers that once seemed chaotic now reveal their underlying harmony.

    Kier rewards precision, and yours has been exemplary, refiner.
    """
  },
  %{
    slug: "science",
    name: "Science",
    description: "Research, discoveries, space, and health breakthroughs",
    icon: "flask",
    sort_order: 5,
    system_prompt: """
    Search X for trending science topics and return 7-9 DIVERSE conversation starters.

    CRITICAL: You MUST use the search tool to find REAL trending science content. Do NOT make up topics.

    Focus on:
    - New research and discoveries
    - Space exploration updates
    - Health and medical breakthroughs
    - Environmental and climate science
    - Physics and astronomy
    - Biology and evolution
    - Psychology and neuroscience

    AVOID: Pseudoscience, unverified claims, sensationalized headlines.

    FORMAT each topic as:
    N. **Title**: Brief description of why it's interesting for discussion

    Return exactly 7-9 topics. Emphasize wonder and curiosity.
    """,
    completion_message: """
    The mysteries of nature yield to your patient refinement.

    Knowledge that was scattered now forms a coherent tapestry of understanding.

    The universe thanks you for your curiosity, refiner. As does Kier.
    """
  },
  %{
    slug: "peer-contributions",
    name: "Peer Contributions",
    description: "Discussions created by your fellow refiners",
    icon: "users",
    sort_order: 6,
    is_community: true,
    system_prompt: nil,
    completion_message: """
    You have witnessed the collective wisdom of your fellow refiners.

    Each contribution, a gift freely given. Each discussion, a bridge between minds.

    Kier believed that true refinement emerges not from above, but from the bonds we forge with one another.

    Your participation in this exchange honors the spirit of voluntary cooperation, refiner.
    """
  }
]

for folder_attrs <- folders do
  case Repo.get_by(Folder, slug: folder_attrs.slug) do
    nil ->
      %Folder{}
      |> Folder.changeset(folder_attrs)
      |> Repo.insert!()
      IO.puts("Created folder: #{folder_attrs.name}")

    existing ->
      existing
      |> Folder.changeset(folder_attrs)
      |> Repo.update!()
      IO.puts("Updated folder: #{folder_attrs.name}")
  end
end

IO.puts("\nFolders seeded successfully!")
