export class User {
    constructor(
        private id: number, 
        private login: string, 
        private password: string,
        private firstName: string,
        private lastName: string,
        private patronymic: string, 
        private mail: string, 
        private passport: string,
        private amount: number, 
        private currency: string) {}
}