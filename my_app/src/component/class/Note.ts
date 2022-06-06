export class Note {
    id: number
    head: string
    body: string
    pined: boolean
    encrypted: Boolean
    lastEdit: Date

    constructor(head = '', body = '', pined = false, encrypted = false, lastEdit = new Date(),  id = -1) {
        this.id = id
        this.head = head
        this.body = body
        this.pined = pined
        this.encrypted = encrypted
        this.lastEdit = lastEdit
    }
}