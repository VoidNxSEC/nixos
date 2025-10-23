#!/bin/bash
# ─────────────────────────────────────────────────────
# 📋 GCloud Format Aliases
# ─────────────────────────────────────────────────────



# ─────────────────────────────────────────────────────
# 📋 PROJECT LISTING
# ─────────────────────────────────────────────────────

alias gcl='gcloud projects list --format=json \
  --limit=1'

alias gcll='gcloud projects list \
  --format=flattened --limit=1'

alias gcla='gcloud projects list \
  --format="table[box,title=Projects](name, \
  lifecycleState)"'

# ─────────────────────────────────────────────────────
# 🌍 ZONE OPERATIONS
# ─────────────────────────────────────────────────────


alias gcl='gcloud projects list --format=json \
  --limit=1'

alias gcll='gcloud projects list \
  --format=flattened --limit=1'

alias gcla='gcloud projects list \
  --format="table[box,title=Projects](name, \
  lifecycleState)"'

alias gcz='gcloud compute instances list \
  --format="json(zone.basename():sort=1:label=zone,name)"'

alias gczl='gcloud compute zones list \
  --format="table[box,title=Zones](id:label=zone_id, \
  selfLink.basename())"'

alias gcza='gcloud compute zones list \
  --format="table[box,title=Zones](name:sort=1:align=center, \
  region.basename():label=region:sort=2, \
  status)"'

alias gczr='gcloud projects list \
  --format="table[box](name:sort=1:reverse, \
  createTime.date('\''%d-%m-%Y'\''))"'

# ─────────────────────────────────────────────────────
# 🔍 FILTERING
# ─────────────────────────────────────────────────────

alias gczj='gcloud compute zones list \
  --filter="region:asia*"'

alias gcjs='gcloud projects list --format=json \
  --filter="NOT \
  parent.type:organization"'

alias gcsj='gcloud projects list --format=json \
  --filter="createTime.date('\''%d-%m-%Y'\'')>1-1-2017"'

# ─────────────────────────────────────────────────────
# 📚 HELP & MANAGEMENT
# ─────────────────────────────────────────────────────

alias gch='gcloud topic filters --help'

alias gpd='gcloud projects delete'
# ─────────────────────────────────────────────────────
#echo "✓ GCloud aliases loaded!"
# ─────────────────────────────────────────────────────

alias gcz='gcloud compute instances list \
  --format="json(zone.basename():sort=1:label=zone,name)"'

alias gczl='gcloud compute zones list \
  --format="table[box,title=Zones](id:label=zone_id, \
  selfLink.basename())"'

alias gcza='gcloud compute zones list \
  --format="table[box,title=Zones](name:sort=1:align=center, \
  region.basename():label=region:sort=2, \
  status)"'

alias gczr='gcloud projects list \
  --format="table[box](name:sort=1:reverse, \
  createTime.date('\''%d-%m-%Y'\''))"'




