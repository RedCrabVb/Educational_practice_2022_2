export class SmartTask {
    id: number
    specific: string
    measurable: string
    achievable: string
    relevant: string
    timeBound: string
    completed: boolean

    constructor(timeBound = new Date(),
        specific = '', measurable = '',
        achievable = '', relevant = '', completed = false, id = -1) {
        this.id = id
        this.specific = specific
        this.measurable = measurable
        this.achievable = achievable
        this.relevant = relevant
        this.timeBound = timeBound.toISOString()
        this.completed = completed
    }
}
