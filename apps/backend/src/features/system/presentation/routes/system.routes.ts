import { Router } from 'express';
import { LogsController } from '../controllers/logs.controller';

export function createSystemRouter(logsController: LogsController): Router {
    const router = Router();

    router.post('/logs', logsController.log.bind(logsController));

    return router;
}
