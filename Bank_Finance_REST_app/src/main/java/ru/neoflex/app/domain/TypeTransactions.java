package ru.neoflex.app.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "t_type_transactions")
@Getter
@Setter
@NoArgsConstructor
public class TypeTransactions {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long typeTransactionsId;
    private String name;
}
