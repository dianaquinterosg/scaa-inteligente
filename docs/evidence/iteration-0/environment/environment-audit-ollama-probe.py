def documentary(value):
    """Conservar resultados y excluir metadatos temporales de la evidencia."""
    if isinstance(value, dict):
        return {k: documentary(v) for k, v in value.items()
                if not k.endswith("_duration") and not k.endswith("_at")
                and k not in {"created", "lastUpdated", "elapsed_seconds"}}
    if isinstance(value, list):
        return [documentary(item) for item in value]
    return value

from pathlib import Path
import json,urllib.request
from pydantic import BaseModel, Field, ConfigDict

class Step(BaseModel):
    model_config=ConfigDict(extra='forbid')
    order:int=Field(gt=0)
    label:str=Field(min_length=1)
    search_term:str=Field(min_length=1)
class Routine(BaseModel):
    model_config=ConfigDict(extra='forbid')
    name:str=Field(min_length=1)
    steps:list[Step]=Field(min_length=1)

result=[]
for description in ['Lavarse las manos','Prepararse para ir al colegio','Preparar una colación']:
    data={'model':'qwen2.5:1.5b','stream':False,'format':Routine.model_json_schema(),'prompt':'Genera una rutina visual sencilla en español para: '+description+'. Devuelve solo JSON con name y de 3 a 5 steps. Cada paso debe tener order (empezando por 1), label y search_term breve para buscar un pictograma. No incluyas explicaciones.','options':{'temperature':0,'num_ctx':2048,'num_predict':400},'keep_alive':'5m'}
    request=urllib.request.Request('http://127.0.0.1:11434/api/generate',data=json.dumps(data).encode(),headers={'Content-Type':'application/json'})
    try:
        with urllib.request.urlopen(request,timeout=120) as response:raw=json.load(response)
        routine=Routine.model_validate_json(raw['response'])
        assert [s.order for s in routine.steps]==list(range(1,len(routine.steps)+1))
        item={'description':description,'schema_valid':True,'ordered_steps':True,'request':data,'response':raw,'validated':routine.model_dump()}
    except Exception as e:
        item={'description':description,'schema_valid':False,'error':repr(e),'request':data}
    result.append(item)
    Path('docs/evidence/iteration-0/environment/environment-audit-ollama-inference-terminal.json').write_text(json.dumps(documentary(result),ensure_ascii=False,indent=2))
    print(json.dumps({k:v for k,v in item.items() if k not in ['request','response']},ensure_ascii=False),flush=True)
with urllib.request.urlopen('http://127.0.0.1:11434/api/ps',timeout=10) as response:ps=json.load(response)
Path('docs/evidence/iteration-0/environment/environment-audit-ollama-ps-terminal.json').write_text(json.dumps(documentary(ps),indent=2))
print('MODELOS EN EJECUCIÓN:',json.dumps(ps),flush=True)
