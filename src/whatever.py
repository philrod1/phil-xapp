import logging
from ricxappframe.xapp_frame import RMRXapp
from constants import Constants

class Whatever:
    def __init__(self, rmr_xapp: RMRXapp):
        self._rmr_xapp = rmr_xapp
        self.logger = logging.getLogger(__name__)

    def send_rmr_payload(self, payload, mtype):
        try:
            res = self._rmr_xapp.rmr_send(payload=payload, mtype=int(mtype))
            self.logger.info(f"{payload} :: {mtype}.  Healthy? {self._rmr_xapp.healthcheck()}")
            return f"{payload} :: {mtype} = {res}"
        except Exception as e:
            self.logger.error(f"Doing whatever {payload} :: {mtype} failed: {str(e)}")
            return f"{payload} :: {mtype} = {e}"