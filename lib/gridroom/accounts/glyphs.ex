defmodule Gridroom.Accounts.Glyphs do
  @moduledoc """
  A pool of 500 strange, surreal glyph identifiers.
  Inspired by the uncanny corporate surrealism of Severance -
  the goat, the waffle party, the egg bar, the perpetuity wing.

  Each user gets assigned one randomly. These are permanent identifiers
  that follow the user like an inexplicable corporate designation.
  """

  # Strange animals - the mundane made unsettling
  @animals ~w(
    goat moth eel heron stoat axolotl newt vole shrew mole
    crane ibis egret bittern rail coot grebe loon murre puffin
    tern skua petrel shearwater fulmar gannet cormorant anhinga
    hare dormouse lemming pika marmot beaver muskrat coypu nutria
    ermine weasel ferret mink badger wolverine otter civet genet
    pangolin aardvark tenrec hedgehog shrew desman mole tarsier
    loris galago potto bushbaby lemur indri sifaka aye-aye fossa
    quoll numbat bilby bandicoot possum cuscus wallaby pademelon
    kiwi kakapo takahe weka pukeko kokako tui bellbird fantail
    gecko skink tuatara basilisk iguana anole chameleon agama
    monitor tegu whiptail racerunner glass-lizard slowworm
    asp viper adder krait mamba taipan copperhead cottonmouth
    sidewinder horned-viper puff-adder gaboon boomslang twig-snake
  )

  # Mundane objects made strange through corporate context
  @objects ~w(
    lamp key door clock mirror frame lever dial gauge valve
    hinge bracket shelf drawer cabinet locker vault safe box
    crate pallet dolly cart trolley bin chute hopper funnel
    spout nozzle tap faucet drain grate vent duct flue stack
    riser conduit raceway tray trough channel gutter culvert
    stapler binder folder sleeve jacket wrapper sheath casing
    gasket washer bushing bearing collar flange coupling union
    tee elbow reducer adapter nipple plug cap ferrule barb
    anvil vise clamp jig fixture template pattern gauge die
    punch drift mandrel arbor collet chuck spindle quill ram
    inkwell blotter rocker cradle pedestal plinth dais lectern
    credenza sideboard hutch armoire chiffonier highboy lowboy
    settee divan ottoman hassock pouf taboret whatnot etagere
  )

  # Abstract concepts and states
  @abstracts ~w(
    void spiral echo drift pulse hum throb surge swell ebb
    flux wane crux apex nadir zenith vertex node nexus hub
    locus focus crux pivot hinge fulcrum lever wedge chock
    shim spacer filler buffer damper baffle shroud cowl hood
    veil pall mantle cloak shroud drape swag valance pelmet
    fringe tassel gimp braid cord rope twine string thread
    wisp strand fiber filament tendril vine creeper trailer
    runner stolon rhizome tuber corm bulb pip kernel stone
    dregs lees marc pomace bagasse chaff bran husk hull shuck
    rind peel zest albedo pith marrow medulla cortex cambium
    phloem xylem stoma guard-cell palisade spongy epidermis
    cuticle bloom pruina glaucous farinose tomentose hirsute
    murk gloom haze mist fog brume haar fret smog pall reek
  )

  # Body-adjacent (clinical, detached)
  @clinical ~w(
    lobe fold ridge groove sulcus gyrus fissure ventricle
    atrium septum valve leaflet cusp annulus chorda papillary
    bundle node tract pathway nucleus ganglion plexus ramus
    foramen canal meatus fossa notch tubercle tuberosity crest
    spine process condyle epicondyle trochlea capitulum head
    neck shaft body base apex margin border angle corner edge
    surface facet aspect view projection profile silhouette
    outline contour shape form figure configuration pattern
    texture grain weave mesh lattice matrix scaffold frame
    membrane sheath capsule fascia aponeurosis tendon ligament
    cartilage meniscus labrum disc annulus nucleus pulposus
  )

  # Nature elements (botanical, geological)
  @nature ~w(
    fern moss lichen liverwort hornwort clubmoss quillwort
    horsetail whisk-fern grape-fern moonwort adder's-tongue
    maidenhair spleenwort polypody bracken hay-scented ostrich
    cinnamon royal interrupted sensitive chain woodsia cliff
    holly lip bladder fragile bulblet walking hart's-tongue
    spore frond pinna pinnule rachis stipe rhizome rootstock
    gneiss schist slate phyllite quartzite marble serpentine
    soapstone talc chlorite actinolite tremolite hornblende
    augite diopside hypersthene enstatite olivine forsterite
    garnet staurolite kyanite sillimanite andalusite cordierite
    vesuvianite epidote zoisite clinozoisite prehnite pumpellyite
    lawsonite glaucophane crossite riebeckite arfvedsonite
    loam till drift moraine esker kame drumlin kettle cirque
    tarn col arete horn nunatak serac crevasse bergschrund
  )

  # Numbers and designations (corporate-bureaucratic)
  @designations ~w(
    unit-7 sector-9 block-14 zone-3 quadrant-8 cell-12 bay-5
    tier-4 level-6 floor-11 wing-2 annex-1 module-15 pod-10
    node-13 hub-16 core-17 shell-18 ring-19 arc-20 segment-21
    phase-22 stage-23 step-24 grade-25 class-26 type-27 kind-28
    sort-29 order-30 rank-31 tier-32 echelon-33 stratum-34
    specimen-alpha specimen-beta specimen-gamma specimen-delta
    sample-001 sample-002 sample-003 sample-004 sample-005
    batch-a batch-b batch-c batch-d batch-e batch-f batch-g
    series-i series-ii series-iii series-iv series-v series-vi
    variant-prime variant-null variant-zero variant-one variant-two
  )

  # Compound phrases (the most Severance-like)
  @compounds ~w(
    cold-harbor quiet-room break-room wellness-session
    waffle-party egg-bar melon-bar finger-trap music-dance
    perpetuity-wing testing-floor severed-floor pip's-vip
    optics-and-design macrodata-refinement o-and-d mdr
    cubicle-inhabitant hallway-wanderer elevator-rider
    badge-wearer lanyard-holder keycard-swiper door-opener
    light-switch break-taker water-cooler coffee-machine
    vending-selection snack-drawer lunch-hour clock-watcher
    file-sorter paper-pusher memo-writer form-filler
    inbox-checker outbox-emptier desk-sitter chair-warmer
    meeting-attender report-reader slide-viewer note-taker
    action-item follow-up circle-back touch-base sync-up
    deep-dive drill-down level-set align-on socialize
    ping-back loop-in flag-up bubble-up trickle-down cascade
  )

  # Time and measurement (clinical precision)
  @temporal ~w(
    minute-47 hour-3 day-12 week-8 month-5 quarter-2 cycle-9
    interval-6 period-11 span-4 duration-7 epoch-1 era-13
    phase-alpha phase-beta phase-gamma phase-delta phase-omega
    mark-zero mark-one mark-two mark-three mark-four mark-five
    reading-a reading-b reading-c reading-d reading-e reading-f
    measure-i measure-ii measure-iii measure-iv measure-v
    index-prime index-null index-void index-full index-half
    ratio-1:1 ratio-2:1 ratio-3:2 ratio-4:3 ratio-5:4 ratio-golden
  )

  @all_glyphs @animals ++ @objects ++ @abstracts ++ @clinical ++
              @nature ++ @designations ++ @compounds ++ @temporal

  @glyph_count length(@all_glyphs)

  @doc """
  Returns a random glyph ID (0 to #{@glyph_count - 1}).
  """
  def random_id do
    :rand.uniform(@glyph_count) - 1
  end

  @doc """
  Returns the glyph name for a given ID.
  """
  def name(id) when is_integer(id) and id >= 0 and id < @glyph_count do
    Enum.at(@all_glyphs, id)
  end

  def name(_), do: "unknown"

  @doc """
  Returns the total number of available glyphs.
  """
  def count, do: @glyph_count

  @doc """
  Returns all glyph names (for validation).
  """
  def all_names, do: @all_glyphs

  @doc """
  Generates a deterministic color from the glyph ID.
  Uses the ID to create a muted, earthy tone fitting the aesthetic.
  """
  def color(id) when is_integer(id) do
    # Use golden ratio to spread colors evenly
    hue = rem(trunc(id * 137.508), 360)
    # Keep saturation low (15-35%) for muted tones
    saturation = 15 + rem(id * 7, 20)
    # Lightness in warm range (35-55%)
    lightness = 35 + rem(id * 11, 20)

    "hsl(#{hue}, #{saturation}%, #{lightness}%)"
  end

  @doc """
  Returns a display format for the glyph: "the [name]" or just "[name]"
  for designations and compounds.
  """
  def display_name(id) when is_integer(id) do
    name = name(id)

    cond do
      String.contains?(name, "-") -> name
      name in @designations -> name
      true -> "the #{name}"
    end
  end
end
