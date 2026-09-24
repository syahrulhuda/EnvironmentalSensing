from app.data.sop_knowledge import SOP_DATABASE

def get_sop(topic: str = "general") -> str:
    """
    Mengambil panduan standar operasional prosedur (SOP) keselamatan bengkel POLTEKOM.
    Topik yang tersedia: 'carbon_monoxide', 'welding_fumes', 'soldering', 'general'.
    """
    key = topic.lower()
    for k in SOP_DATABASE:
        if k in key:
            return SOP_DATABASE[k]
    return SOP_DATABASE["general"]
