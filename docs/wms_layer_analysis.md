# Slovenian WMS Layers - SAR Application Analysis

**Total Layers Found: 108**

## HIGH PRIORITY - Critical for SAR Operations

### Aerial Imagery & Base Maps (5 layers)
1. **pregledovalnik:DOF_2024** - Digital Orthophoto 2024 (Latest aerial imagery)
   - **USE CASE**: Primary visual reference, current terrain conditions
   - **ALREADY IMPLEMENTED** in the app

2. **pregledovalnik:DOF25** - Digital Orthophoto 25cm resolution
   - **USE CASE**: High-resolution aerial imagery for detailed terrain analysis

3. **pregledovalnik:DOF_IR** - Infrared Orthophoto
   - **USE CASE**: Thermal/infrared imagery for detecting heat signatures, useful for night searches

4. **pregledovalnik:DTK25** - Topographic Map 1:25,000
   - **USE CASE**: Traditional topographic reference with contours, trails, landmarks

5. **pregledovalnik:dof025_2022_2024** - Combined orthophoto 2022-2024
   - **USE CASE**: Multi-year aerial imagery comparison

### Administrative Boundaries (6 layers)
6. **pregledovalnik:NEP_RPE_OBCINE** - Municipalities (občine)
   - **USE CASE**: Jurisdiction boundaries for coordinating with local authorities
   - **RECOMMENDED FOR OVERLAY**

7. **pregledovalnik:NEP_RPE_NASELJA** - Settlements
   - **USE CASE**: Identify populated areas, evacuation points, staging areas
   - **RECOMMENDED FOR OVERLAY**

8. **pregledovalnik:NEP_HISNE_STEVILKE** - House Numbers
   - **USE CASE**: Precise location identification for emergency response

9. **pregledovalnik:NEP_RPE_UPRAVNE_ENOTE** - Administrative Units
   - **USE CASE**: Regional administration boundaries

10. **pregledovalnik:NEP_RPE_STATISTICNE_REGIJE** - Statistical Regions
    - **USE CASE**: Broader regional planning

11. **pregledovalnik:drzavna_meja** - State Border
    - **USE CASE**: International coordination for cross-border operations

### Roads & Transportation (4 layers)
12. **pregledovalnik:KGI_LINIJE_CESTE_G** - Roads
    - **USE CASE**: Primary access routes, evacuation routes, vehicle navigation
    - **HIGH PRIORITY OVERLAY**

13. **pregledovalnik:gozdne_ceste** - Forest Roads
    - **USE CASE**: Access to remote forest areas, critical for SAR vehicles
    - **HIGH PRIORITY OVERLAY**

14. **pregledovalnik:LINIJE_ZELEZNICE_G** - Railways
    - **USE CASE**: Alternative access routes, landmarks, coordination with rail authorities

15. **pregledovalnik:KGI_LINIJE_PLANINSKE_POTI_G** - Mountain/Hiking Trails
    - **USE CASE**: Common search areas, lost hiker routes, access to remote areas
    - **HIGH PRIORITY OVERLAY**

### Fire & Emergency Hazards (5 layers)
16. **pregledovalnik:gozdni_pozari** - Forest Fires (historical)
    - **USE CASE**: Historical fire locations, high-risk areas
    - **RECOMMENDED FOR OVERLAY**

17. **pregledovalnik:pozarna_ogrozenost** - Fire Hazard/Risk Areas
    - **USE CASE**: Identify high fire risk zones, plan safe evacuation routes
    - **HIGH PRIORITY OVERLAY**

18. **pregledovalnik:pozarisce_goriski_kras** - Fire Site - Goriški Kras
    - **USE CASE**: Specific fire hazard area in Karst region

19. **pregledovalnik:pozarisce_kras** - Fire Site - Kras
    - **USE CASE**: Karst region fire zones

20. **pregledovalnik:protipozarne_preseke** - Firebreaks
    - **USE CASE**: Fire containment lines, safe zones

### Geographic Names & Navigation (1 layer)
21. **pregledovalnik:zemljepisna_imena** - Geographic Names
    - **USE CASE**: Place names for communication, location identification
    - **RECOMMENDED FOR OVERLAY**

---

## MEDIUM PRIORITY - Useful for Planning & Context

### Protected Areas & Natural Features (9 layers)
22. **pregledovalnik:natura2000** - Natura 2000 Protected Areas
    - **USE CASE**: Environmental restrictions, sensitive areas

23. **pregledovalnik:zavarovana_obmocja_poligoni** - Protected Areas (polygons)
    - **USE CASE**: National parks, nature reserves, access restrictions

24. **pregledovalnik:zavarovana_obmocja_tocke** - Protected Areas (points)
    - **USE CASE**: Point-based protected sites

25. **pregledovalnik:zavarovana_obmocja_conacija** - Protected Areas (zoning)
    - **USE CASE**: Zoning within protected areas

26. **pregledovalnik:naravne_vrednote_poligoni** - Natural Heritage (polygons)
    - **USE CASE**: Notable natural features, landmarks

27. **pregledovalnik:naravne_vrednote_tocke** - Natural Heritage (points)
    - **USE CASE**: Specific natural landmarks (caves, waterfalls, etc.)

28. **pregledovalnik:epo_poligoni** - Single Trees/Monuments (polygons)
    - **USE CASE**: Notable landmark trees

29. **pregledovalnik:epo_tocke** - Single Trees/Monuments (points)
    - **USE CASE**: Point landmarks

30. **pregledovalnik:gozdni_rezervati** - Forest Reserves
    - **USE CASE**: Old-growth forests, restricted access areas

### Cadastral & Land Parcels (2 layers)
31. **pregledovalnik:kn_parcele** - Cadastral Parcels
    - **USE CASE**: Land ownership boundaries, legal jurisdictions

32. **pregledovalnik:KN_KATASTRSKE_OBCINE** - Cadastral Municipalities
    - **USE CASE**: Cadastral administrative units

### Terrain & Elevation (2 layers)
33. **pregledovalnik:DMK** - Digital Cartographic Model
    - **USE CASE**: Contours, terrain features, elevation data

34. **pregledovalnik:DMR** - Digital Relief Model
    - **USE CASE**: Shaded relief, terrain visualization

### Forest Management Areas (10 layers)
35. **pregledovalnik:gge** - Forest Management Units (GGE)
    - **USE CASE**: Forest administrative units, contact local foresters

36. **pregledovalnik:ggo** - Forest Management Districts (GGO)
    - **USE CASE**: Larger forest districts

37. **pregledovalnik:revirji** - Forest Ranger Districts
    - **USE CASE**: Local ranger contact areas

38. **pregledovalnik:krajevne_enote** - Local Forest Units
    - **USE CASE**: Smallest administrative forest units

39. **pregledovalnik:odseki** - Forest Compartments
    - **USE CASE**: Forest subdivisions for management

40. **pregledovalnik:odseki_gozdni** - Forest Compartments (variant)
    - **USE CASE**: Alternative compartment layer

41. **pregledovalnik:sestoji** - Forest Stands
    - **USE CASE**: Specific tree stand types, vegetation density

42. **pregledovalnik:sestoji_druga_gozdna_zemljisca** - Other Forest Lands
    - **USE CASE**: Non-productive forest areas

43. **pregledovalnik:varovalni_gozdovi** - Protection Forests
    - **USE CASE**: Forests with protective function (avalanche, erosion)

44. **pregledovalnik:lovisca** - Hunting Grounds
    - **USE CASE**: Contact with hunting associations for local knowledge

### Historical Disasters (6 layers)
45. **pregledovalnik:vetrolom_2017** - Windthrow 2017
    - **USE CASE**: Storm damage areas, difficult terrain

46. **pregledovalnik:vetrolom_2018** - Windthrow 2018
    - **USE CASE**: Storm damage areas from 2018

47. **pregledovalnik:zled_2014** - Ice Storm 2014
    - **USE CASE**: Ice damage areas

48. **pregledovalnik:zled_drugi_gozdovi_2014** - Ice Storm 2014 (other forests)
    - **USE CASE**: Ice damage in secondary forests

49. **pregledovalnik:podlubniki_2015_2019** - Bark Beetle Damage 2015-2019
    - **USE CASE**: Dead wood areas, fire hazard, difficult terrain

50. **pregledovalnik:krcitve** - Clearcuts
    - **USE CASE**: Open areas, recent harvest sites, potential staging areas

### Agricultural & Land Use (2 layers)
51. **pregledovalnik:povrsine_v_zarascanju** - Overgrown Areas
    - **USE CASE**: Abandoned agricultural land, changing terrain

52. **pregledovalnik:skupna_kmetijska_politika_2023_2027** - Common Agricultural Policy
    - **USE CASE**: Agricultural land use planning

---

## LOW PRIORITY - Technical/Specialized Layers

### Forest Function Layers (ON21 series - 45 layers)
These are highly specialized forest function layers from the 2021 forest management plan. Each has variants for lines (_l), polygons (_p), and points (_t):

**Categories:**
- **Biotska** (Biodiversity): on21_fun_biotska_l/p/t
- **Druge gozdne dobrine** (Other forest goods): on21_fun_druge_gozdne_dobrine_l/p/t
- **Estetska** (Aesthetic): on21_fun_estetska_l/p/t
- **Hidroloska** (Hydrological): on21_fun_hidroloska_l/p/t
- **Higiensko-zdravstvena** (Health/hygiene): on21_fun_higiensko_zdravstvena_p
- **Klimatska** (Climate): on21_fun_klimatska_l/p
- **Kulturna** (Cultural): on21_fun_kulturna_l/p/t
- **Lesnoproizvodna** (Timber production): on21_fun_lesnoproizvodna_p
- **Lovnogospodarska** (Hunting management): on21_fun_lovnogospodarska_p/t
- **Obrambna** (Defense): on21_fun_obrambna_p/t
- **Poucna** (Educational): on21_fun_poucna_l/p/t
- **Raziskovalna** (Research): on21_fun_raziskovalna_p/t
- **Rekreacijska** (Recreation): on21_fun_rekreacijska_l/p/t
- **Skupaj** (Combined): on21_fun_skupaj_l/p/t
- **Turisticna** (Tourism): on21_fun_turisticna_l/p/t
- **Varovalna** (Protection): on21_fun_varovalna_p
- **Varovanja naravnih vrednot** (Natural heritage protection): on21_fun_varovanja_naravnih_vrednot_l/p/t
- **Zascitna** (Conservation): on21_fun_zascitna_l/p

**USE CASE**: Very specialized forest planning data. May be useful for:
- **Rekreacijska**: Popular recreation areas (lost hikers)
- **Turisticna**: Tourist areas (search priority)
- **Varovalna**: Avalanche/erosion protection forests (hazard awareness)

### Miscellaneous Technical (6 layers)
- **pregledovalnik:conacija_gp** - Zonation (technical)
- **pregledovalnik:evrd** - Single-tree selection forests
- **pregledovalnik:koridorji** - Corridors (ecological)
- **pregledovalnik:luo** - Forest landscape units
- **pregledovalnik:pobude_gge** - GGE initiatives
- **pregledovalnik:provenience** - Seed provenance areas
- **pregledovalnik:uvhvvr** - High conservation value forests
- **pregledovalnik:gozdni_sklad_ekocelice** - Forest fund eco-cells
- **pregledovalnik:gozdni_sklad_habitatna_drevesa** - Habitat trees

### Layer Groups (2 layers)
- **pregledovalnik:ttn_group** - Group layer (container)
- **pregledovalnik:zemljevid_group** - Map group layer (container)

---

## RECOMMENDED IMPLEMENTATION PLAN

### Phase 1: Critical Overlays (Immediate)
Add these layers as toggleable overlays in the Map Options screen:

1. **Forest Roads** (`gozdne_ceste`) - PNG, transparent
   - Critical for vehicle access in remote areas
   
2. **Hiking/Mountain Trails** (`KGI_LINIJE_PLANINSKE_POTI_G`) - PNG, transparent
   - Common search areas for lost hikers
   
3. **Fire Hazard Zones** (`pozarna_ogrozenost`) - PNG, transparent
   - Safety planning, risk assessment
   
4. **Settlements** (`NEP_RPE_NASELJA`) - PNG, transparent
   - Populated areas, staging areas
   
5. **Municipalities** (`NEP_RPE_OBCINE`) - PNG, transparent
   - Administrative boundaries

### Phase 2: Additional Useful Layers
6. **Geographic Names** (`zemljepisna_imena`)
7. **Forest Fires Historical** (`gozdni_pozari`)
8. **Protected Areas** (`zavarovana_obmocja_poligoni`)
9. **Topographic Map** (`DTK25`) - Alternative base layer
10. **Infrared Imagery** (`DOF_IR`) - Alternative base layer

### Phase 3: Specialized Layers (On Demand)
11. **Windthrow/Disaster Areas** (for post-disaster operations)
12. **Recreation/Tourism Areas** (for prioritizing search areas)
13. **Protection Forests** (avalanche/erosion hazard awareness)

---

## TECHNICAL NOTES

### CRS Compatibility
- All layers from `prostor.zgs.gov.si` support **EPSG:3794** (Slovenian National Grid)
- The app already has the correct CRS implementation in `lib/utils/slovenian_crs.dart`

### Recommended Formats
- **Base Layers**: JPEG (better compression for imagery)
- **Overlays**: PNG with transparency=true (for stacking)

### Caching Strategy
- All layers should use the existing FMTC caching infrastructure
- 30-day validity is appropriate for most layers
- Consider longer validity for static layers (administrative boundaries)

### Performance Considerations
- Limit active overlays to 3-4 simultaneously to avoid performance issues
- Use appropriate zoom level restrictions (some layers only useful at close zoom)
- Consider pre-downloading critical layers for offline SAR operations

---

## LAYER NAMING CONVENTIONS

**Slovenian Terms Reference:**
- **DOF** = Digitalni Ortofoto (Digital Orthophoto)
- **DTK** = Državna Topografska Karta (State Topographic Map)
- **DMK** = Digitalni Kartografski Model (Digital Cartographic Model)
- **DMR** = Digitalni Model Reliefa (Digital Relief Model)
- **NEP** = Nacionalni Evidenčni Portal (National Registry Portal)
- **RPE** = Register Prostorskih Enot (Spatial Units Register)
- **GGE** = Gozdnogospodarska Enota (Forest Management Unit)
- **GGO** = Gozdnogospodarska Območje (Forest Management District)
- **ON21** = Območni Načrt 2021 (Regional Plan 2021)

